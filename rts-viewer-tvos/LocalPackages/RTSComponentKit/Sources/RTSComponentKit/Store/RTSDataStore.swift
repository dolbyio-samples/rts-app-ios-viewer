//
//  RTSDataStore.swift
//

import Foundation
import MillicastSDK
import SwiftUI

open class RTSDataStore: ObservableObject {

    public enum SubscriptionError: Error, Equatable {
        case subscribeError(reason: String)
        case connectError(reason: String)
    }

    public enum State: Equatable {
        case streamInactive
        case streamActive
        case connected
        case subscribed
        case disconnected
        case error(SubscriptionError)
    }

    @Published public private(set) var dimensions: Dimensions = .init(width: 0, height: 0)
    @Published public var subscribeState: State = .disconnected
    @Published public var statisticsData: StatisticsData?

    @Published public var detailedVideoQualityList = [DetailedVideoQuality]() {
        didSet {
            videoQualityList = detailedVideoQualityList.map { $0.quality }
        }
    }
    @Published public var videoQualityList: [VideoQuality] = []

    @Published public var selectedDetailedVideoQuality = DetailedVideoQuality.auto {
        didSet {
            selectedVideoQuality = selectedDetailedVideoQuality.quality
        }
    }

    public typealias StreamDetail = (streamName: String, accountID: String)

    @Published public var selectedVideoQuality = VideoQuality.auto
    @Published public var mainVideoTrack: MCVideoTrack?
    @Published public var streamDetail: StreamDetail?

    public var mainAudioTrack: MCAudioTrack?
    private var statsReport: MCStatsReport?
    private let videoRenderer: MCIosVideoRenderer = MCIosVideoRenderer(openGLRenderer: true)

    private var subscriptionManager: SubscriptionManagerProtocol?
    private var taskStateObservation: Task<Void, Never>?
    private var activityObservation: Task<Void, Never>?
    private var tracksObservation: Task<Void, Never>?
    private var statsObservation: Task<Void, Never>?
    private var layersObservation: Task<Void, Never>?

    // MARK: Subscribe API methods

    public init() {
        // Configure the AVAudioSession with our settings.
        Utils.configureAudioSession(isSubscriber: true)
    }

    open func connect() async throws -> Bool {
        guard let streamDetail = streamDetail else {
            return false
        }

        return try await connect(streamName: streamDetail.streamName, accountID: streamDetail.accountID)
    }

    open func connect(
        streamName: String,
        accountID: String,
        subscriptionManager: SubscriptionManagerProtocol = SubscriptionManager()
    ) async throws -> Bool {
        registerToSubscriberStreams()
        self.subscriptionManager = subscriptionManager
        self.streamDetail = (streamName: streamName, accountID: accountID)
        return try await subscriptionManager.connect(streamName: streamName, accountID: accountID)
    }

    open func startSubscribe() async throws -> Bool {
        guard let subscriptionManager else { return false }
        return try await subscriptionManager.startSubscribe()
    }

    open func stopSubscribe() async throws -> Bool {
        defer { deregisterToSubscriberStreams() }
        guard let subscriptionManager else { return false }
        let success = try await subscriptionManager.stopSubscribe()

        updateState(to: .disconnected)
        self.subscriptionManager = nil

        return success
    }

    open func selectLayer(videoQuality: VideoQuality) async throws {
        guard let subscriptionManager else { return }

        guard !detailedVideoQualityList.isEmpty else {
            return
        }

        selectedVideoQuality = videoQuality
        selectedDetailedVideoQuality = detailedVideoQualityList.matching(videoQuality: videoQuality) ?? .auto
        _ = try await subscriptionManager.selectLayer(layer: selectedDetailedVideoQuality.layer)
    }
}

// MARK: Observations

extension RTSDataStore {

    // swiftlint:disable cyclomatic_complexity function_body_length
    func registerToSubscriberStreams() {
        Task {
            guard let subscriptionManager else { return }

            self.taskStateObservation = Task {
                for await state in subscriptionManager.state {
                    switch state {
                    case .connected:
                        updateState(to: .connected)

                    case .disconnected:
                        updateState(to: .disconnected)

                    case .subscribed:
                        updateState(to: .subscribed)

                    case .connectionError(status: _, reason: let reason):
                        updateState(to: .error(.connectError(reason: reason)))

                    case .signalingError:
                        break
                    }
                }
            }

            self.tracksObservation = Task {
                for await trackEvent in subscriptionManager.tracks {
                    switch trackEvent {
                    case let .audio(track: track, mid: _):
                        self.mainAudioTrack = track

                    case let .video(track: track, mid: _):
                        await MainActor.run {
                            self.mainVideoTrack = track
                            self.mainVideoTrack?.add(videoRenderer)
                        }
                    }
                }
            }

            self.activityObservation = Task {
                for await activityEvent in subscriptionManager.activity {
                    switch activityEvent {
                    case .active:
                        updateState(to: .streamActive)

                    case .inactive:
                        await MainActor.run {
                            detailedVideoQualityList.removeAll()
                            selectedDetailedVideoQuality = .auto
                            self.subscribeState = .streamInactive
                        }
                    }
                }
            }

            self.layersObservation = Task {
                for await layerEvent in subscriptionManager.layers {
                    await MainActor.run {
                        var layersForSelection: [MCLayerData] = []

                        // Simulcast active layers
                        let simulcastLayers = layerEvent.activeLayers.filter({ !$0.encodingId.isEmpty })
                        let svcLayers = layerEvent.activeLayers.filter({ $0.spatialLayerId != nil })
                        if !simulcastLayers.isEmpty {
                            // Select the max (best) temporal layer Id from a specific encodingId
                            let dictionaryOfLayersMatchingEncodingId = Dictionary(grouping: simulcastLayers, by: { $0.encodingId })
                            dictionaryOfLayersMatchingEncodingId.forEach { (_: String, layers: [MCLayerData]) in
                                // Picking the layer matching the max temporal layer id - represents the layer with the best FPS
                                if let layerWithBestFrameRate = layers.first(where: { $0.temporalLayerId == $0.maxTemporalLayerId }) ?? layers.last {
                                    layersForSelection.append(layerWithBestFrameRate)
                                }
                            }
                            layersForSelection.sort(by: >)
                        }
                        // Using SVC layer selection logic
                        else {
                            let dictionaryOfLayersMatchingSpatialLayerId = Dictionary(grouping: svcLayers, by: { $0.spatialLayerId! })
                            dictionaryOfLayersMatchingSpatialLayerId.forEach { (_: NSNumber, layers: [MCLayerData]) in
                                // Picking the layer matching the max temporal layer id - represents the layer with the best FPS
                                if let layerWithBestFrameRate = layers.first(where: { $0.spatialLayerId == $0.maxSpatialLayerId }) ?? layers.last {
                                    layersForSelection.append(layerWithBestFrameRate)
                                }
                            }
                        }

                        layersForSelection = layersForSelection
                            .sorted { lhs, rhs in
                                if let rhsLayerResolution = rhs.layerResolution, let lhsLayerResolution = lhs.layerResolution {
                                    return rhsLayerResolution.width < lhsLayerResolution.width || rhsLayerResolution.height < rhsLayerResolution.height
                                } else {
                                    return rhs.bitrate < lhs.bitrate
                                }
                            }

                        let totalLayers = layersForSelection.count
                        switch totalLayers {
                        case 2:
                            detailedVideoQualityList = [
                                .auto,
                                .high(layersForSelection[0]),
                                .low(layersForSelection[1])
                            ]
                        case 3...Int.max:
                            detailedVideoQualityList = [
                                .auto,
                                .high(layersForSelection[0]),
                                .medium(layersForSelection[1]),
                                .low(layersForSelection[2])
                            ]
                        default:
                            detailedVideoQualityList = [.auto]
                        }
                    }
                }
            }

            self.statsObservation = Task {
                for await statsEvent in subscriptionManager.statsReport {
                    let value = getStatisticsData(report: statsEvent)
                    await MainActor.run {
                        self.statisticsData = value

                        let videoWidth = videoRenderer.getWidth()
                        let videoHeight = videoRenderer.getHeight()

                        if frameWidth != videoWidth || frameHeight != videoHeight {
                            dimensions = Dimensions(width: videoWidth, height: videoHeight)
                        }
                    }
                }
            }

            _ = await [
                self.taskStateObservation?.value,
                self.tracksObservation?.value,
                self.activityObservation?.value,
                self.layersObservation?.value,
                self.statsObservation?.value
            ]
        }
    }
    // swiftlint:enable cyclomatic_complexity function_body_length

    func deregisterToSubscriberStreams() {
        self.taskStateObservation = nil
        self.tracksObservation = nil
        self.activityObservation = nil
        self.layersObservation = nil
        self.statsObservation = nil
    }

    var frameWidth: Float {
        dimensions.width
    }

    var frameHeight: Float {
        dimensions.height
    }
}

// MARK: Private Helpers

extension RTSDataStore {
    private func updateState(to state: State) {
        Task {
            await MainActor.run {
                self.subscribeState = state
            }
        }
    }

    private func getStatisticsData(report: MCStatsReport?) -> StatisticsData? {
        var result: StatisticsData?
        let inboundRtpStreamStatsType = MCInboundRtpStreamStats.get_type()
        let rtt: Double? = getStatisticsRoundTripTime(report: report)
        if let statsReport = report?.getStatsOf(inboundRtpStreamStatsType) {
            var audio: StatsInboundRtp?
            var video: StatsInboundRtp?
            for stats in statsReport {
                guard let statsReportData = stats as? MCInboundRtpStreamStats else { return nil }
                var codecName: String?
                if let codecId = statsReportData.codec_id as String? {
                    codecName = getStatisticsCodec(codecId: codecId, report: report)
                }
                let statsInboundRtp: StatsInboundRtp = StatsInboundRtp(
                    sid: statsReportData.sid as String,
                    kind: statsReportData.kind as String,
                    decoder: statsReportData.decoder_implementation as String?,
                    frameWidth: Int(statsReportData.frame_width),
                    frameHeight: Int(statsReportData.frame_height),
                    fps: Int(statsReportData.frames_per_second),
                    audioLevel: Int(statsReportData.audio_level),
                    totalEnergy: statsReportData.total_audio_energy,
                    framesReceived: Int(statsReportData.frames_received),
                    framesDecoded: Int(statsReportData.frames_decoded),
                    nackCount: Int(statsReportData.nack_count),
                    bytesReceived: Int(statsReportData.bytes_received),
                    totalSampleDuration: statsReportData.total_samples_duration,
                    codecId: statsReportData.codec_id as String?,
                    jitter: statsReportData.jitter,
                    packetsReceived: Double(statsReportData.packets_received),
                    packetsLost: Double(statsReportData.packets_lost),
                    timestamp: Double(statsReportData.timestamp),
                    codecName: codecName
                )
                if statsInboundRtp.isVideo {
                    video = statsInboundRtp
                } else {
                    audio = statsInboundRtp
                }
            }
            result = StatisticsData(roundTripTime: rtt, audio: audio, video: video)
        }
        return result
    }

    private func getStatisticsRoundTripTime(report: MCStatsReport?) -> Double? {
        let receivedType = MCRemoteInboundRtpStreamStats.get_type()
        var roundTripTime: Double?
        if let statsReport = report?.getStatsOf(receivedType) {
            for stats in statsReport {
                guard let s = stats as? MCRemoteInboundRtpStreamStats else { return nil }
                roundTripTime = Double(s.round_trip_time)
            }
        }
        return roundTripTime
    }

    private func getStatisticsCodec(codecId: String, report: MCStatsReport?) -> String? {
        let codecType = MCCodecsStats.get_type()
        guard
            let statsReport = report?.getStatsOf(codecType),
            let codecStats = statsReport.first(where: { $0 is MCCodecsStats && $0.sid as String == codecId }) as? MCCodecsStats
        else {
            return nil
        }

        return codecStats.mime_type as String
    }
}

extension MCLayerData: Comparable {
    public static func < (lhs: MCLayerData, rhs: MCLayerData) -> Bool {
        switch (lhs.encodingId.lowercased(), rhs.encodingId.lowercased()) {
        case ("h", "m"), ("l", "m"), ("h", "s"), ("l", "s"), ("m", "s"):
            return false
        default:
            return true
        }
    }
}

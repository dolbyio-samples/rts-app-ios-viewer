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

    // Note - Publishers are exposed as settable interfaces for Debug builds
    // So as to easy alter them from unit tests
    // Only applies to DEBUG builds
    #if DEBUG
    @Published public var subscribeState: State = .disconnected
    @Published public var isAudioEnabled: Bool = true
    @Published public var isVideoEnabled: Bool = true
    @Published public var statisticsData: StatisticsData?
    @Published public var activeStreamType = [StreamType]()
    @Published public var layerActiveMap: [MCLayerData]?
    @Published public var dimensions: Dimensions = .init(width: 0, height: 0)
    @Published public var streamName: String?
    #else
    @Published public private(set) var subscribeState: State = .disconnected
    @Published public private(set) var isAudioEnabled: Bool = true
    @Published public private(set) var isVideoEnabled: Bool = true
    @Published public private(set) var statisticsData: StatisticsData?
    @Published public private(set) var activeStreamType = [StreamType]()
    @Published public private(set) var layerActiveMap: [MCLayerData]?
    @Published public private(set) var dimensions: Dimensions = .init(width: 0, height: 0)
    @Published public private(set) var streamName: String?
    #endif
    @Published public var activeLayer = StreamType.auto

    private let videoRenderer: MCIosVideoRenderer
    private var subscriptionManager: SubscriptionManagerProtocol?
    private var taskStateObservation: Task<Void, Never>?
    private var activityObservation: Task<Void, Never>?
    private var tracksObservation: Task<Void, Never>?
    private var statsObservation: Task<Void, Never>?
    private var layersObservation: Task<Void, Never>?

    private typealias StreamDetail = (streamName: String, accountID: String)
    private var streamDetail: StreamDetail?
    private var audioTrack: MCAudioTrack?
    private var videoTrack: MCVideoTrack?
    private var statsReport: MCStatsReport?

    public init(videoRenderer: MCIosVideoRenderer = MCIosVideoRenderer(openGLRenderer: true)) {
        self.videoRenderer = videoRenderer
    }

    // MARK: Subscribe API methods

    open func toggleAudioState() {
        setAudio(!isAudioEnabled)
    }

    open func setAudio(_ enable: Bool) {
        audioTrack?.enable(enable)
        Task {
            await MainActor.run {
                isAudioEnabled = enable
            }
        }
    }

    open func toggleVideoState() {
        setVideo(!isVideoEnabled)
    }

    open func setVideo(_ enable: Bool) {
        videoTrack?.enable(enable)
        Task {
            await MainActor.run {
                isVideoEnabled = enable
            }
        }
    }

    open func setVolume(_ volume: Double) {
        audioTrack?.setVolume(volume)
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
        self.streamName = streamName
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

        setAudio(false)
        setVideo(false)

        videoTrack?.remove(videoRenderer)

        audioTrack = nil
        videoTrack = nil

        updateState(to: .disconnected)
        self.subscriptionManager = nil

        return success
    }

    open func subscriptionView() -> UIView {
        videoRenderer.getView()
    }

    @discardableResult
    open func selectLayer(streamType: StreamType) async throws -> Bool {
        guard let subscriptionManager else { return false }

        guard layerActiveMap != nil else {
            return false
        }

        activeLayer = streamType
        return try await subscriptionManager.selectLayer(layer: layer(for: streamType))
    }

}

// MARK: Helper functions

private extension RTSDataStore {
    var frameWidth: Float {
        dimensions.width
    }

    var frameHeight: Float {
        dimensions.height
    }

    func layer(for streamType: StreamType) -> MCLayerData? {
        guard let layerActiveMap = layerActiveMap else {
            return nil
        }
        switch (streamType, layerActiveMap.count) {
        case (.auto, _):
            return nil
        case (.high, _): // High resolution stream is always at index - 0
            return layerActiveMap[0]
        case (.medium, 2): // Medium resolution only exists when the active layer count is `3`
            return nil
        case (.medium, 3): // Medium resolution only exists when the active layer count is `3` and the index position will be 1
            return layerActiveMap[1]
        case (.low, 2): // Low resolution will be at Index 1 when there is a total `two` active layers
            return layerActiveMap[1]
        case (.low, 3): // Low resolution will be at Index 2 when there is a total `three` active layers
            return layerActiveMap[2]
        default:
            return nil
        }
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
                        audioTrack = track
                        setAudio(true)
                        // Configure the AVAudioSession with our settings.
                        Utils.configureAudioSession(isSubscriber: true)

                    case let .video(track: track, mid: _):
                        videoTrack = track
                        setVideo(true)
                        track.add(videoRenderer)
                    }
                }
            }

            self.activityObservation = Task {
                for await acitivityEvent in subscriptionManager.activity {
                    switch acitivityEvent {
                    case .active:
                        updateState(to: .streamActive)

                    case .inactive:
                        layerActiveMap = nil
                        updateState(to: .streamInactive)
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

                        layerActiveMap = layersForSelection

                        activeStreamType.removeAll()

                        switch layerActiveMap?.count {
                        case 2: activeStreamType += [StreamType.auto, StreamType.high, StreamType.low]
                        case 3: activeStreamType += [StreamType.auto, StreamType.high, StreamType.medium, StreamType.low]
                        default: break
                        }
                    }
                }
            }

            self.statsObservation = Task {
                for await statsEvent in subscriptionManager.statsReport {
                    let value = getStatisticsData(report: statsEvent)
                    await MainActor.run {
                        self.statisticsData = value
                    }

                    let videoWidth = videoRenderer.getWidth()
                    let videoHeight = videoRenderer.getHeight()

                    if frameWidth != videoWidth || frameHeight != videoHeight {
                        dimensions = Dimensions(width: videoWidth, height: videoHeight)
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

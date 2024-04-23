//
//  RTSDataStore.swift
//

import Foundation
import MillicastSDK
import SwiftUI

open class RTSDataStore: ObservableObject {

    public struct SubscribedState: Equatable {
        public fileprivate(set) var mainVideoTrack: MCVideoTrack?
        public fileprivate(set) var statisticsData: StatisticsData?

        public init(mainVideoTrack: MCVideoTrack? = nil, statisticsData: StatisticsData? = nil) {
            self.mainVideoTrack = mainVideoTrack
            self.statisticsData = statisticsData
        }
    }

    public enum SubscriptionError: Error, Equatable {
        case signalingError(reason: String)
        case connectError(status: Int32, reason: String)
    }

    public enum State: Equatable {
        case connected
        case subscribed(state: SubscribedState)
        case disconnected
        case stopped
        case error(SubscriptionError)
    }

    public typealias StreamDetail = (streamName: String, accountID: String)

    @Published public var streamDetail: StreamDetail?
    @Published public var state: State = .disconnected
    @Published public var videoQualityList: [VideoQuality] = []
    @Published public var selectedVideoQuality = VideoQuality.auto

    private var mainVideoTrack: MCVideoTrack?
    private var detailedVideoQualityList = [DetailedVideoQuality]() {
        didSet {
            videoQualityList = detailedVideoQualityList.map { $0.quality }
        }
    }

    private var selectedDetailedVideoQuality = DetailedVideoQuality.auto {
        didSet {
            selectedVideoQuality = selectedDetailedVideoQuality.quality
        }
    }

    private var mainSourceId: String?

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

    open func connect(
        streamName: String,
        accountID: String,
        subscriptionManager: SubscriptionManagerProtocol = SubscriptionManager()
    ) async throws -> Bool {
        self.subscriptionManager = subscriptionManager
        self.streamDetail = (streamName: streamName, accountID: accountID)

        registerToSubscriberStreams()
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

        self.streamDetail = nil
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
        Task { [weak self] in
            guard let self, let subscriptionManager = self.subscriptionManager else { return }

            self.taskStateObservation = Task {
                for await state in subscriptionManager.state {
                    switch state {
                    case .connected:
                        self.updateState(to: .connected)

                    case .disconnected:
                        self.mainVideoTrack = nil
                        self.updateState(to: .disconnected)

                    case .subscribed:
                        // No-op
                        break

                    case let .connectionError(status: status, reason: reason):
                        self.mainVideoTrack = nil
                        self.updateState(to: .error(.connectError(status: status, reason: reason)))

                    case .signalingError(reason: let reason):
                        self.mainVideoTrack = nil
                        self.updateState(to: .error(.signalingError(reason: reason)))
                    }
                }
            }

            self.tracksObservation = Task {
                for await trackEvent in subscriptionManager.tracks {
                    switch trackEvent {
                    case .audio:
                        break

                    case let .video(track: track, mid: _):
                        self.mainVideoTrack = track
                        self.updateState(to: .subscribed(state: .init(mainVideoTrack: track)))
                    }
                }
            }

            self.activityObservation = Task {
                for await activityEvent in subscriptionManager.activity {
                    switch activityEvent {
                    case let .active(streamId: _, tracks: _, sourceId: sourceId):
                        if self.mainSourceId == nil {
                            self.mainSourceId = sourceId

                            if let mainVideoTrack = self.mainVideoTrack {
                                self.updateState(to: .subscribed(state: .init(mainVideoTrack: mainVideoTrack)))
                            }
                        }

                    case let .inactive(streamId: _, sourceId: sourceId):
                        if sourceId == self.mainSourceId {
                            self.detailedVideoQualityList.removeAll()
                            self.selectedDetailedVideoQuality = .auto
                            self.mainSourceId = nil
                            self.updateState(to: .stopped)
                        }
                    }
                }
            }

            self.layersObservation = Task {
                for await layerEvent in subscriptionManager.layers {
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
                    let topSimulcastLayers = Array(layersForSelection.prefix(3))
                    switch topSimulcastLayers.count {
                    case 2:
                        self.detailedVideoQualityList = [
                            .auto,
                            .high(topSimulcastLayers[0]),
                            .low(topSimulcastLayers[1])
                        ]
                    case 3...Int.max:
                        self.detailedVideoQualityList = [
                            .auto,
                            .high(topSimulcastLayers[0]),
                            .medium(topSimulcastLayers[1]),
                            .low(topSimulcastLayers[2])
                        ]
                    default:
                        self.detailedVideoQualityList = [.auto]
                    }
                }
            }

            self.statsObservation = Task {
                for await statsEvent in subscriptionManager.statsReport {
                    guard let stats = self.getStatisticsData(report: statsEvent) else {
                        return
                    }
                    self.updateStats(stats)
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

private extension RTSDataStore {

    func updateStats(_ stats: StatisticsData) {
        switch state {
        case let .subscribed(state: subscribedState):
            var updatedSubscribedState = subscribedState
            updatedSubscribedState.statisticsData = stats
            self.state = .subscribed(state: updatedSubscribedState)
        default:
            break
        }
    }

    func updateSubscribedState() {
        switch state {
        case let .subscribed(state: subscribedState):
            self.state = .subscribed(state: subscribedState)
        default:
            break
        }
    }

    func updateState(to state: State) {
        self.state = state
    }
}

extension RTSDataStore {
    func getStatisticsData(report: MCStatsReport?) -> StatisticsData? {
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

    func getStatisticsRoundTripTime(report: MCStatsReport?) -> Double? {
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

    func getStatisticsCodec(codecId: String, report: MCStatsReport?) -> String? {
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

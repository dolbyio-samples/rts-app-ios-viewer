//
//  RTSDataStore.swift
//  RTSViewer
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
    @Published public var activeLayer = StreamType.auto
    @Published public var dimensions: Dimensions = .init(width: 0, height: 0)
    @Published public var streamName: String?
    #else
    @Published public private(set) var subscribeState: State = .disconnected
    @Published public private(set) var isAudioEnabled: Bool = true
    @Published public private(set) var isVideoEnabled: Bool = true
    @Published public private(set) var statisticsData: StatisticsData?
    @Published public private(set) var activeStreamType = [StreamType]()
    @Published public private(set) var layerActiveMap: [MCLayerData]?
    @Published public private(set) var activeLayer = StreamType.auto
    @Published public private(set) var dimensions: Dimensions = .init(width: 0, height: 0)
    @Published public private(set) var streamName: String?
    #endif

    private let videoRenderer: MCIosVideoRenderer
    private let subscriptionManager: SubscriptionManagerProtocol

    private typealias StreamDetail = (streamName: String, accountID: String)
    private var streamDetail: StreamDetail?
    private var audioTrack: MCAudioTrack?
    private var videoTrack: MCVideoTrack?
    private var statsReport: MCStatsReport?

    public init(
        subscriptionManager: SubscriptionManagerProtocol = SubscriptionManager(),
        videoRenderer: MCIosVideoRenderer = MCIosVideoRenderer()
    ) {
        self.subscriptionManager = subscriptionManager
        self.videoRenderer = videoRenderer
        self.subscriptionManager.delegate = self
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

    open func connect() async -> Bool {
        guard let streamDetail = streamDetail else {
            return false
        }

        return await connect(streamName: streamDetail.streamName, accountID: streamDetail.accountID)
    }

    open func connect(streamName: String, accountID: String) async -> Bool {
        self.streamDetail = (streamName: streamName, accountID: accountID)
        self.streamName = streamName
        return await subscriptionManager.connect(streamName: streamName, accountID: accountID)
    }

    open func startSubscribe() async -> Bool {
        await subscriptionManager.startSubscribe()
    }

    open func stopSubscribe() async -> Bool {
        let success = await subscriptionManager.stopSubscribe()

        setAudio(false)
        setVideo(false)

        audioTrack = nil
        videoTrack = nil

        videoTrack?.remove(videoRenderer)

        updateState(to: .disconnected)

        return success
    }

    open func subscriptionView() -> UIView {
        videoRenderer.getView()
    }

    @discardableResult
    open func selectLayer(streamType: StreamType) -> Bool {
        guard layerActiveMap != nil else {
            return false
        }

        activeLayer = streamType
        return subscriptionManager.selectLayer(layer: layer(for: streamType))
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

// MARK: SubscriptionManagerDelegate implementation

extension RTSDataStore: SubscriptionManagerDelegate {

    public func onStreamActive() {
        updateState(to: .streamActive)
    }

    public func onStreamInactive() {
        updateState(to: .streamInactive)
    }

    public func onStreamStopped() {
        layerActiveMap = nil
        updateState(to: .streamInactive)
    }

    public func onSubscribed() {
        updateState(to: .subscribed)
    }

    public func onSubscribedError(_ reason: String) {
        updateState(to: .error(.subscribeError(reason: reason)))
    }

    public func onVideoTrack(_ track: MCVideoTrack, withMid mid: String) {
        videoTrack = track
        setVideo(true)
        track.add(videoRenderer)
    }

    public func onAudioTrack(_ track: MCAudioTrack, withMid mid: String) {
        audioTrack = track
        setAudio(true)
        // Configure the AVAudioSession with our settings.
        Utils.configureAudioSession()
    }

    public func onStatsReport(report: MCStatsReport) {
        self.statsReport = report
        let value = getStatisticsData(report: report)
        Task {
            await MainActor.run {
                self.statisticsData = value
            }
        }

        let videoWidth = videoRenderer.getWidth()
        let videoHeight = videoRenderer.getHeight()

        if frameWidth != videoWidth || frameHeight != videoHeight {
            dimensions = Dimensions(width: videoWidth, height: videoHeight)
        }
    }

    public func onConnected() {
        updateState(to: .connected)
    }

    public func onConnectionError(reason: String) {
        updateState(to: .error(.connectError(reason: reason)))
    }

    public func onStreamLayers(_ mid: String?, activeLayers: [MCLayerData]?, inactiveLayers: [MCLayerData]?) {
        Task {
            await MainActor.run {
                layerActiveMap = activeLayers?.filter { layer in
                    // For H.264 there are no temporal layers and the id is set to 255. For VP8 use the first temporal layer.
                    return layer.temporalLayerId == 0 || layer.temporalLayerId == 255
                }

                activeStreamType.removeAll()

                switch layerActiveMap?.count {
                case 2: activeStreamType += [StreamType.auto, StreamType.high, StreamType.low]
                case 3: activeStreamType += [StreamType.auto, StreamType.high, StreamType.medium, StreamType.low]
                default: break
                }
            }
        }
    }

    // MARK: Private Helpers

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
                    framesBitDepth: Int(statsReportData.frame_bit_depth),
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

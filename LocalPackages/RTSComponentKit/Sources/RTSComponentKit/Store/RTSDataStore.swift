//
//  RTSDataStore.swift
//  RTSViewer
//

import Foundation
import MillicastSDK
import SwiftUI

public final class RTSDataStore: ObservableObject {

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

    @Published public private(set) var subscribeState: State = .disconnected
    @Published public private(set) var isAudioEnabled: Bool = true
    @Published public private(set) var isVideoEnabled: Bool = true
    @Published public var statisticsData: StatisticsData?

    private let videoRenderer: MCIosVideoRenderer
    private var subscriptionManager: SubscriptionManager!

    private typealias StreamDetail = (streamName: String, accountID: String)
    private var streamDetail: StreamDetail?
    private var audioTrack: MCAudioTrack?
    private var videoTrack: MCVideoTrack?
    private var statsReport: MCStatsReport?

    @Published public private(set) var layerActiveMap: [MCLayerData]?

    init(subscriptionManager: SubscriptionManager, videoRenderer: MCIosVideoRenderer) {
        self.subscriptionManager = subscriptionManager
        self.videoRenderer = videoRenderer
        self.subscriptionManager.delegate = self
    }

    public convenience init() {
        self.init(
            subscriptionManager: SubscriptionManager(),
            videoRenderer: MCIosVideoRenderer()
        )
        self.subscriptionManager.delegate = self
    }

    // MARK: Subscribe API methods

    public func toggleAudioState() {
        setAudio(!isAudioEnabled)
    }

    public func setAudio(_ enable: Bool) {
        audioTrack?.enable(enable)
        Task {
            await MainActor.run {
                isAudioEnabled = enable
            }
        }
    }

    public func toggleVideoState() {
        setVideo(!isVideoEnabled)
    }

    public func setVideo(_ enable: Bool) {
        videoTrack?.enable(enable)
        Task {
            await MainActor.run {
                isVideoEnabled = enable
            }
        }
    }

    public func setVolume(_ volume: Double) {
        audioTrack?.setVolume(volume)
    }

    public func connect() async -> Bool {
        guard let streamDetail = streamDetail else {
            return false
        }

        return await connect(streamName: streamDetail.streamName, accountID: streamDetail.accountID)
    }

    public func connect(streamName: String, accountID: String) async -> Bool {
        self.streamDetail = (streamName: streamName, accountID: accountID)
        return await subscriptionManager.connect(streamName: streamName, accountID: accountID)
    }

    public func startSubscribe() async -> Bool {
        await subscriptionManager.startSubscribe()
    }

    public func stopSubscribe() async -> Bool {
        let success = await subscriptionManager.stopSubscribe()

        setAudio(false)
        setVideo(false)

        audioTrack = nil
        videoTrack = nil

        videoTrack?.remove(videoRenderer)

        updateState(to: .disconnected)

        return success
    }

    public func subscriptionView() -> UIView {
        videoRenderer.getView()
    }

    @discardableResult
    public func selectLayer(streamType: StreamType) -> Bool {
        switch streamType {
        case .auto:
            return subscriptionManager.selectLayer(layer: nil)
        case .high:
            return subscriptionManager.selectLayer(layer: layerActiveMap?[0])
        case .medium:
            return subscriptionManager.selectLayer(layer: layerActiveMap?[1])
        case .low:
            return subscriptionManager.selectLayer(layer: layerActiveMap?[2])
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

    func onStatsReport(report: MCStatsReport) {
        self.statsReport = report
        let value = getStatisticsData(report: report)
        Task {
            await MainActor.run {
                self.statisticsData = value
            }
        }
    }

    public func onConnected() {
        updateState(to: .connected)
    }

    public func onConnectionError(reason: String) {
        updateState(to: .error(.connectError(reason: reason)))
    }

    public func updateState(to state: State) {
        Task {
            await MainActor.run {
                self.subscribeState = state
            }
        }
    }

    func onStreamLayers(_ mid: String?, activeLayers: [MCLayerData]?, inactiveLayers: [MCLayerData]?) {
        Task {
            await MainActor.run {
                layerActiveMap = activeLayers
            }
        }
    }

    private func getStatisticsData(report: MCStatsReport?) -> StatisticsData? {
        var result: StatisticsData?
        let inboundRtpStreamStatsType = MCInboundRtpStreamStats.get_type()
        let rtt: Double? = getStatisticsRountTripTime(report: report)
        if let statsReport = report?.getStatsOf(inboundRtpStreamStatsType) {
            var audio: StatsInboundRtp?
            var video: StatsInboundRtp?
            for stats in statsReport {
                guard let s = stats as? MCInboundRtpStreamStats else { return nil }
                let statsInboundRtp: StatsInboundRtp = StatsInboundRtp(
                    sid: s.sid as String,
                    decoder: s.decoder_implementation as String?,
                    frameWidth: Int(s.frame_width),
                    frameHeight: Int(s.frame_height),
                    fps: Int(s.frames_per_second),
                    audioLevel: Int(s.audio_level),
                    totalEnergy: s.total_audio_energy,
                    framesReceived: Int(s.frames_received),
                    framesDecoded: Int(s.frames_decoded),
                    framesBitDepth: Int(s.frame_bit_depth),
                    nackCount: Int(s.nack_count),
                    bytesReceived: Int(s.bytes_received),
                    totalSampleDuration: s.total_samples_duration,
                    codecId: s.codec_id as String?,
                    jitter: s.jitter,
                    packetsReceived: Double(s.packets_received),
                    packetsLost: Double(s.packets_lost),
                    timestamp: Double(s.timestamp)
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

    private func getStatisticsRountTripTime(report: MCStatsReport?) -> Double? {
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
}

public struct StatisticsData {
    public private(set) var roundTripTime: Double?
    public private(set) var audio: StatsInboundRtp?
    public private(set) var video: StatsInboundRtp?
    init(roundTripTime: Double?, audio: StatsInboundRtp?, video: StatsInboundRtp?) {
        self.roundTripTime = roundTripTime
        self.audio = audio
        self.video = video
    }
}

public struct StatsInboundRtp {
    public private(set) var sid: String
    public private(set) var decoder: String?
    public private(set) var frameWidth: Int
    public private(set) var frameHeight: Int
    public private(set) var videoResolution: String
    public private(set) var fps: Int
    public private(set) var audioLevel: Int
    public private(set) var totalEnergy: Double
    public private(set) var framesReceived: Int
    public private(set) var framesDecoded: Int
    public private(set) var framesBitDepth: Int
    public private(set) var nackCount: Int
    public private(set) var bytesReceived: Int
    public private(set) var totalSampleDuration: Double
    public private(set) var codec: String?
    public private(set) var jitter: Double
    public private(set) var packetsReceived: Double
    public private(set) var packetsLost: Double
    public private(set) var timestamp: Double

    public private(set) var isVideo: Bool
    init(sid: String, decoder: String?, frameWidth: Int, frameHeight: Int, fps: Int, audioLevel: Int, totalEnergy: Double, framesReceived: Int, framesDecoded: Int, framesBitDepth: Int, nackCount: Int, bytesReceived: Int, totalSampleDuration: Double, codecId: String?, jitter: Double, packetsReceived: Double, packetsLost: Double, timestamp: Double) {

        self.sid = sid
        self.decoder = decoder
        self.frameWidth = frameWidth
        self.frameHeight = frameHeight
        self.fps = fps
        self.audioLevel = audioLevel
        self.totalEnergy = totalEnergy
        self.framesReceived = framesReceived
        self.framesDecoded = framesDecoded
        self.framesBitDepth = framesBitDepth
        self.nackCount = nackCount
        self.bytesReceived = bytesReceived
        self.totalSampleDuration = totalSampleDuration
        self.codec = codecId

        self.jitter = jitter
        self.packetsReceived = packetsReceived
        self.packetsLost = packetsLost

        self.timestamp = timestamp

        if sid.starts(with: "RTCInboundRTPVideoStream") {
            isVideo = true
        } else {
            isVideo = false
        }

        self.videoResolution = String(format: "%d x %d", frameWidth, frameHeight)
    }
}

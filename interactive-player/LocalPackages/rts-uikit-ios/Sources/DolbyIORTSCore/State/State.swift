//
//  State.swift
//

import Foundation
import MillicastSDK

struct VideoTrackAndMid {
    let videoTrack: MCVideoTrack
    let mid: String
}

struct AudioTrackAndMid {
    let audioTrack: MCAudioTrack
    let mid: String
}

enum State: CustomStringConvertible {
    case disconnected
    case connected
    case subscribed(SubscribedState)
    case stopped
    case error(ErrorState)

    var description: String {
        switch self {
        case .disconnected:
            return "disconnected"
        case .connected:
            return "connected"
        case .subscribed:
            return "subscribed"
        case .stopped:
            return "stopped"
        case let .error(state):
            return "error \(state.error.localizedDescription)"
        }
    }
}

struct SubscribedState {

    private(set) var streamSourceBuilders: [StreamSourceBuilder]
    private(set) var numberOfStreamViewers: Int
    private(set) var streamingStats: AllStreamStatistics?
    private(set) var configuration: SubscriptionConfiguration

    init(configuration: SubscriptionConfiguration) {
        self.configuration = configuration
        streamSourceBuilders = []
        numberOfStreamViewers = 0
    }

    mutating func add(streamId: String, sourceId: String?, tracks: [String], cachedVideoTrackDetail: VideoTrackAndMid? = nil, cachedAudioTrackDetail: AudioTrackAndMid? = nil) {
        let streamSourceBuilder = StreamSourceBuilder(streamId: streamId, sourceId: sourceId, tracks: tracks)
        if let videoTrackAndMid = cachedVideoTrackDetail {
            streamSourceBuilder.addVideoTrack(videoTrackAndMid.videoTrack, mid: videoTrackAndMid.mid)
        }
        if let audioTrackAndMid = cachedAudioTrackDetail {
            streamSourceBuilder.addAudioTrack(audioTrackAndMid.audioTrack, mid: audioTrackAndMid.mid)
        }
        streamSourceBuilders.append(streamSourceBuilder)
    }

    mutating func remove(streamId: String, sourceId: String?) {
        streamSourceBuilders.removeAll { $0.streamId == streamId && $0.sourceId == StreamSource.SourceId(id: sourceId) }
    }

    func addAudioTrack(_ track: MCAudioTrack, mid: String) {
        guard !configuration.disableAudio else {
            return
        }
        guard let builder = streamSourceBuilders.first(where: { $0.hasMissingAudioTrack}) else {
            return
        }
        builder.addAudioTrack(track, mid: mid)
    }

    func addVideoTrack(_ track: MCVideoTrack, mid: String) {
        guard let builder = streamSourceBuilders.first(where: { $0.hasMissingVideoTrack }) else {
            return
        }
        builder.addVideoTrack(track, mid: mid)
    }

    mutating func removeBuilder(with sourceId: StreamSource.SourceId) {
        guard let indexToRemove = streamSourceBuilders.firstIndex(where: { $0.sourceId == sourceId }) else {
            return
        }

        streamSourceBuilders.remove(at: indexToRemove)
    }

    func setPlayingAudio(_ enable: Bool, for sourceId: StreamSource.SourceId) {
        guard let builder = streamSourceBuilders.first(where: { $0.sourceId == sourceId }) else {
            return
        }
        builder.setPlayingAudio(enable)
    }

    func setPlayingVideo(_ enable: Bool, for sourceId: StreamSource.SourceId) {
        guard let builder = streamSourceBuilders.first(where: { $0.sourceId == sourceId }) else {
            return
        }
        builder.setPlayingVideo(enable)
    }

    func setAvailableStreamTypes(_ list: [StreamSource.LowLevelVideoQuality], for mid: String) {
        guard let builder = streamSourceBuilders.first(where: { $0.videoTrack?.trackInfo.mid == mid }) else {
            return
        }

        builder.setAvailableVideoQualityList(list)
    }

    func setSelectedVideoQuality(_ videoQuality: VideoQuality, for sourceId: StreamSource.SourceId) {
        guard let builder = streamSourceBuilders.first(where: { $0.sourceId == sourceId }) else {
            return
        }
        builder.setSelectedVideoQuality(videoQuality)
    }

    mutating func updateViewerCount(_ count: Int) {
        numberOfStreamViewers = count
    }

    mutating func updateStreamingStatistics(_ stats: AllStreamStatistics) {
        streamingStats = stats
        stats.videoStatsInboundRtpList.forEach { videoStats in
            guard let builder = streamSourceBuilders.first(
                where: { $0.videoTrack?.trackInfo.mid == videoStats.mid }
            ) else {
                return
            }
            let sourceStatistics = StreamingStatistics(
                roundTripTime: stats.roundTripTime,
                videoStatsInboundRtp: videoStats,
                audioStatsInboundRtp: stats.audioStatsInboundRtpList.first
            )
            builder.setStatistics(sourceStatistics)
        }
    }

    var sources: [StreamSource] {
        streamSourceBuilders.compactMap {
            do {
                return try $0.build(isAudioEnabled: !configuration.disableAudio)
            } catch {
                return nil
            }
        }
    }
}

struct ErrorState: Equatable {
    let error: StreamError
}

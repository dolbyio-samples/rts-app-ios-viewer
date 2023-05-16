//
//  State.swift
//

import Foundation
import MillicastSDK

enum State: CustomStringConvertible {
    case disconnected
    case connecting(ConnectingState)
    case connected(ConnectedState)
    case subscribing(SubscribingState)
    case subscribed(SubscribedState)
    case stopped
    case error(ErrorState)

    var description: String {
        switch self {
        case .disconnected:
            return "disconnected"
        case .connecting:
            return "connecting"
        case .connected:
            return "connected"
        case .subscribing:
            return "subscribing"
        case .subscribed:
            return "subscribed"
        case .stopped:
            return "stopped"
        case let .error(state):
            return "error \(state.error.localizedDescription)"
        }
    }
}

struct ConnectingState {
    let streamDetail: StreamDetail
}

struct ConnectedState {
    let streamDetail: StreamDetail
}

struct SubscribingState {
    let streamDetail: StreamDetail
}

struct SubscribedState {

    private(set) var streamSourceBuilders: [StreamSourceBuilder]
    private(set) var numberOfStreamViewers: Int
    private(set) var streamingStats: StreamingStatistics?
    let streamDetail: StreamDetail

    init(streamDetail: StreamDetail) {
        streamSourceBuilders = []
        numberOfStreamViewers = 0
        self.streamDetail = streamDetail
    }

    mutating func add(streamId: String, sourceId: String?, tracks: [String]) {
        streamSourceBuilders.append(
            StreamSourceBuilder.init(streamId: streamId, sourceId: sourceId, tracks: tracks)
        )
    }

    mutating func remove(streamId: String, sourceId: String?) {
        streamSourceBuilders.removeAll { $0.streamId == streamId && $0.sourceId.value == sourceId }
    }

    func addAudioTrack(_ track: MCAudioTrack, mid: String) {
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

    mutating func removeBuilder(with sourceId: String?) {
        guard let indexToRemove = streamSourceBuilders.firstIndex(where: { $0.sourceId.value == sourceId }) else {
            return
        }

        streamSourceBuilders.remove(at: indexToRemove)
    }

    func updatePreferredVideoQuality(_ videoQuality: StreamSource.VideoQuality, for sourceId: String?) {
        guard let builder = streamSourceBuilders.first(where: { $0.sourceId.value == sourceId }) else {
            return
        }
        builder.updatePreferredVideoQuality(videoQuality)
    }

    func setPlayingAudio(_ enable: Bool, for sourceId: String?) {
        guard let builder = streamSourceBuilders.first(where: { $0.sourceId.value == sourceId }) else {
            return
        }
        builder.setPlayingAudio(enable)
    }

    func setPlayingVideo(_ enable: Bool, for sourceId: String?) {
        guard let builder = streamSourceBuilders.first(where: { $0.sourceId.value == sourceId }) else {
            return
        }
        builder.setPlayingVideo(enable)
    }

    func setAvailableStreamTypes(_ list: [StreamSource.VideoQuality], for mid: String) {
        guard let builder = streamSourceBuilders.first(where: { $0.videoTrack?.trackInfo.mid == mid }) else {
            return
        }

        builder.setAvailableVideoQualityList(list)
    }

    mutating func updateViewerCount(_ count: Int) {
        numberOfStreamViewers = count
    }

    mutating func updateStreamingStatistics(_ stats: StreamingStatistics?) {
        streamingStats = stats
    }

    var sources: [StreamSource] {
        streamSourceBuilders.compactMap {
            do {
                return try $0.build()
            } catch {
                return nil
            }
        }
    }
}

struct ErrorState: Equatable {
    let error: StreamError
    let streamDetail: StreamDetail
}

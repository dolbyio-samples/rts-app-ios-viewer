//
//  StateMachine.swift
//

import Combine
import Foundation
import MillicastSDK
import os

final class StateMachine {
    private static let logger = Logger.make(category: String(describing: StateMachine.self))

    private(set) var currentState: State {
        didSet {
            stateSubject.send(currentState)
            Self.logger.debug("🎰 State change from \(oldValue.description) to \(self.currentState.description)")
        }
    }

    private let stateSubject: PassthroughSubject<State, Never> = PassthroughSubject()
    lazy var statePublisher: AnyPublisher<State, Never> = stateSubject.eraseToAnyPublisher()
    private(set) var cachedSourceZeroVideoTrackAndMid: VideoTrackAndMid?
    private(set) var cachedSourceZeroAudioTrackAndMid: AudioTrackAndMid?
    private(set) var configuration: SubscriptionConfiguration

    init(initialState: State) {
        currentState = initialState
        configuration = .init()
    }

    func startConnection(streamName: String, accountID: String, configuration: SubscriptionConfiguration) {
        self.configuration = configuration
    }

    func stopSubscribe() {
        currentState = .disconnected
    }

    func setPlayingAudio(_ enable: Bool, for source: StreamSource) {
        switch currentState {
        case let .subscribed(state):
            state.setPlayingAudio(enable, for: source.sourceId)
            currentState = .subscribed(state)
        default:
            Self.logger.error("🛑 Unexpected state on setPlayingAudio - \(self.currentState.description)")
        }
    }

    func setPlayingVideo(_ enable: Bool, for source: StreamSource) {
        switch currentState {
        case let .subscribed(state):
            state.setPlayingVideo(enable, for: source.sourceId)
            currentState = .subscribed(state)
        default:
            Self.logger.error("🛑 Unexpected state on setPlayingVideo - \(self.currentState.description)")
        }
    }

    func onConnected() {
        switch currentState {
        case .connected, .subscribed:
            break
        default:
            currentState = .connected
        }
    }

    func onConnectionError(_ status: Int32, withReason reason: String) {
        currentState = .error(.init(error: .connectFailed(reason: reason, status: status)))
    }

    func onDisconnected() {
        currentState = .disconnected
    }

    func onSubscribed() {
        if case .subscribed = currentState {
            return
        }
        currentState = .subscribed(.init(configuration: configuration))
    }

    func onSubscribedError(_ reason: String) {
        currentState = .error(.init(error: .subscribeFailed(reason: reason)))
    }

    func onSignalingError(_ message: String) {
        currentState = .error(.init(error: .signalingError(reason: message)))
    }

    func onActive(_ streamId: String, tracks: [String], sourceId: String?) {
        // This is a workaround for an SDK behaviour where the some `onActive` callbacks arrive even before the `onSubscribed`
        // In this case it's safe to assume a state change to `.subscribed` provided the current state is `.connected`
        if case .connected = currentState {
            // Mimic an `onSubscribed` callback
            onSubscribed()
        }

        switch currentState {
        case var .subscribed(state):
            if let sourceId = sourceId, !sourceId.isEmpty {
                state.add(streamId: streamId, sourceId: sourceId, tracks: tracks)
            } else {
                state.add(
                    streamId: streamId,
                    sourceId: sourceId,
                    tracks: tracks,
                    cachedVideoTrackDetail: cachedSourceZeroVideoTrackAndMid,
                    cachedAudioTrackDetail: cachedSourceZeroAudioTrackAndMid
                )
                cachedSourceZeroAudioTrackAndMid = nil
                cachedSourceZeroAudioTrackAndMid = nil
            }
            self.currentState = .subscribed(state)
        default:
            Self.logger.error("🛑 Unexpected state on onActive - \(self.currentState.description)")
        }
    }

    func onInactive(_ streamId: String, sourceId: String?) {
        switch currentState {
        case var .subscribed(state):
            state.remove(streamId: streamId, sourceId: sourceId)
            currentState = .subscribed(state)
        default:
            Self.logger.error("🛑 Unexpected state on onInactive - \(self.currentState.description)")
        }
    }

    func onVideoTrack(_ track: MCVideoTrack, withMid mid: String) {
        switch currentState {
        case let .subscribed(state):
            state.addVideoTrack(track, mid: mid)
            currentState = .subscribed(state)

        default:
            self.cachedSourceZeroVideoTrackAndMid = VideoTrackAndMid(videoTrack: track, mid: mid)
            Self.logger.error("🛑 Unexpected state on onVideoTrack - \(self.currentState.description)")
        }
    }

    func onAudioTrack(_ track: MCAudioTrack, withMid mid: String) {
        switch currentState {
        case let .subscribed(state):
            state.addAudioTrack(track, mid: mid)
            currentState = .subscribed(state)
        default:
            self.cachedSourceZeroAudioTrackAndMid = AudioTrackAndMid(audioTrack: track, mid: mid)
            Self.logger.error("🛑 Unexpected state on onAudioTrack - \(self.currentState.description)")
        }
    }

    func onLayers(_ mid: String, activeLayers: [MCLayerData], inactiveLayers: [String]) {
        switch currentState {
        case let .subscribed(state):
            let streamTypes: [StreamSource.LowLevelVideoQuality]
            var layersForSelection: [MCLayerData] = []

            // Simulcast active layers
            let simulcastLayers = activeLayers.filter { !$0.encodingId.isEmpty }
            if !simulcastLayers.isEmpty {
                // Select the max (best) temporal layer Id from a specific encodingId
                let dictionaryOfLayersMatchingEncodingId = Dictionary(grouping: simulcastLayers, by: { $0.encodingId })
                dictionaryOfLayersMatchingEncodingId.forEach { (_: String, layers: [MCLayerData]) in
                    // Picking the layer matching the max temporal layer id - represents the layer with the best FPS
                    if let layerWithBestFrameRate = layers.first { $0.temporalLayerId == $0.maxTemporalLayerId } ?? layers.last {
                        layersForSelection.append(layerWithBestFrameRate)
                    }
                }
                layersForSelection.sort(by: >)
            }
            // Using SVC layer selection logic
            else {
                let simulcastLayers = activeLayers.filter { $0.spatialLayerId != nil }
                let dictionaryOfLayersMatchingSpatialLayerId = Dictionary(grouping: simulcastLayers, by: { $0.spatialLayerId! })
                dictionaryOfLayersMatchingSpatialLayerId.forEach { (_: NSNumber, layers: [MCLayerData]) in
                    // Picking the layer matching the max temporal layer id - represents the layer with the best FPS
                    if let layerWithBestFrameRate = layers.first { $0.spatialLayerId == $0.maxSpatialLayerId } ?? layers.last {
                        layersForSelection.append(layerWithBestFrameRate)
                    }
                }
            }

            layersForSelection = Array(layersForSelection.prefix(3))
            switch layersForSelection.count {
            case 2:
                streamTypes = [
                    .auto,
                    .high(layer: layersForSelection[0]),
                    .low(layer: layersForSelection[1])
                ]
            case 3:
                streamTypes = [
                    .auto,
                    .high(layer: layersForSelection[0]),
                    .medium(layer: layersForSelection[1]),
                    .low(layer: layersForSelection[2])
                ]
            default:
                streamTypes = [.auto]
            }

            state.setAvailableStreamTypes(streamTypes, for: mid)
            currentState = .subscribed(state)
        default:
            Self.logger.error("🛑 Unexpected state on onLayers - \(self.currentState.description)")
        }
    }

    func selectVideoQuality(_ quality: VideoQuality, for source: StreamSource) {
        switch currentState {
        case let .subscribed(state):
            state.setSelectedVideoQuality(quality, for: source.sourceId)
            currentState = .subscribed(state)
        default:
            Self.logger.error("🛑 Unexpected state on selectVideoQuality - \(self.currentState.description)")
        }
    }

    func onStatsReport(_ streamingStats: AllStreamStatistics) {
        switch currentState {
        case var .subscribed(state):
            state.updateStreamingStatistics(streamingStats)
            currentState = .subscribed(state)
        default:
            Self.logger.error("🛑 Unexpected state on onStatsReport - \(self.currentState.description)")
        }
    }

    func updateNumberOfStreamViewers(_ count: Int32) {
        switch currentState {
        case var .subscribed(state):
            state.updateViewerCount(Int(count))
            currentState = .subscribed(state)
        default:
            Self.logger.error("🛑 Unexpected state on onViewerCount - \(self.currentState.description)")
        }
    }

    func onStopped() {
        currentState = .stopped
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

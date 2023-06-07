//
//  StreamCoordinator.swift
//

import Combine
import Foundation
import MillicastSDK
import os

public struct StreamCoordinatorConfiguration {
    let retryOnConnectionError = true
    let retryTimeInterval: TimeInterval = 5
    let subscribeOnSuccessfulConnection = true
}

open class StreamCoordinator {

    public static let shared: StreamCoordinator = StreamCoordinator()

    private let stateMachine: StateMachine = StateMachine(initialState: .disconnected)
    private let subscriptionManager: SubscriptionManagerProtocol
    private let rendererRegistry: RendererRegistryProtocol
    private let taskScheduler: TaskSchedulerProtocol

    private static var configuration: StreamCoordinatorConfiguration = .init()

    private var subscriptions: Set<AnyCancellable> = []
    private lazy var stateSubject: CurrentValueSubject<StreamState, Never> = CurrentValueSubject(.disconnected)
    public lazy var statePublisher: AnyPublisher<StreamState, Never> = stateSubject
        .removeDuplicates()
        .eraseToAnyPublisher()
    public private(set) var activeStreamDetail: StreamDetail?

    private init() {
        subscriptionManager = SubscriptionManager()
        taskScheduler = TaskScheduler()
        rendererRegistry = RendererRegistry()

        subscriptionManager.delegate = self

        startStateObservation()
    }

    #if DEBUG
    init(
        subscriptionManager: SubscriptionManagerProtocol,
        taskScheduler: TaskSchedulerProtocol,
        rendererRegistry: RendererRegistryProtocol
    ) {
        self.subscriptionManager = subscriptionManager
        self.taskScheduler = taskScheduler
        self.rendererRegistry = rendererRegistry

        self.subscriptionManager.delegate = self

        startStateObservation()
    }
    #endif

    private func startStateObservation() {
        Task {
            await stateMachine.statePublisher
                .sink { [weak self] state in
                    guard let self = self else { return }

                    // Populate updates public facing states
                    self.stateSubject.send(StreamState(state: state))
                }
            .store(in: &subscriptions)
        }
    }

    static func setStreamCoordinatorConfiguration(_ configuration: StreamCoordinatorConfiguration) {
        Self.configuration = configuration
    }

    // MARK: Subscribe API methods

    public func connect(streamName: String, accountID: String) async -> Bool {
        await stateMachine.startConnection(streamName: streamName, accountID: accountID)
        let result = await subscriptionManager.connect(streamName: streamName, accountID: accountID)
        if result {
            activeStreamDetail = StreamDetail(streamName: streamName, accountID: accountID)
        }
        return result
    }

    public func startSubscribe() async -> Bool {
        await stateMachine.startSubscribe()
        return await subscriptionManager.startSubscribe()
    }

    public func stopSubscribe() async -> Bool {
        activeStreamDetail = nil
        async let stateResetResult: Void = stateMachine.stopSubscribe()
        async let rendererResetResult: Void = rendererRegistry.reset()
        async let stopSubscribeResult: Bool = await subscriptionManager.stopSubscribe()
        let (_, _, success) = await (stateResetResult, rendererResetResult, stopSubscribeResult)
        return success
    }

    public func selectVideoQuality(_ quality: StreamSource.VideoQuality, for source: StreamSource) {
        subscriptionManager.selectVideoQuality(quality, for: source)
    }

    public func playAudio(for source: StreamSource) async {
        switch stateSubject.value {
        case let .subscribed(sources: sources, numberOfStreamViewers: _):
            guard
                let matchingSource = sources.first(where: { $0.id == source.id }),
                !matchingSource.isPlayingAudio
            else {
                return
            }

            sources.forEach { source in
                if source.isPlayingAudio {
                    Task {
                        await stateMachine.setPlayingAudio(false, for: source)
                    }
                    subscriptionManager.unprojectAudio(for: source)
                }
            }
            subscriptionManager.projectAudio(for: source)
            await stateMachine.setPlayingAudio(true, for: source)

        default:
            return
        }
    }

    public func stopAudio(for source: StreamSource) async {
        switch stateSubject.value {
        case let .subscribed(sources: sources, numberOfStreamViewers: _):
            guard
                let matchingSource = sources.first(where: { $0.id == source.id }),
                matchingSource.isPlayingAudio
            else {
                return
            }
            subscriptionManager.unprojectAudio(for: source)
            await stateMachine.setPlayingAudio(false, for: source)

        default:
            return
        }
    }

    public func playVideo(for source: StreamSource, on renderer: StreamSourceViewRenderer, quality: StreamSource.VideoQuality) async {
        switch stateSubject.value {
        case let .subscribed(sources: sources, numberOfStreamViewers: _):
            guard
                let matchingSource = sources.first(where: { $0.id == source.id }),
                let videoTrack = source.videoTrack?.track
            else {
                return
            }
            await rendererRegistry.registerRenderer(renderer, for: videoTrack)

            if !matchingSource.isPlayingVideo {
                subscriptionManager.projectVideo(for: source, withQuality: quality)
                _ = await (
                    stateMachine.setPlayingVideo(true, for: source),
                    stateMachine.selectVideoQuality(quality, for: source)
                )
            }

        default:
            return
        }
    }

    public func stopVideo(for source: StreamSource, on renderer: StreamSourceViewRenderer) async {
        switch stateSubject.value {
        case let .subscribed(sources: sources, numberOfStreamViewers: _):
            guard
                let matchingSource = sources.first(where: { $0.id == source.id }),
                matchingSource.isPlayingVideo,
                let videoTrack = source.videoTrack?.track
            else {
                return
            }
            await rendererRegistry.deregisterRenderer(renderer, for: videoTrack)

            if !(await rendererRegistry.hasActiveRenderer(for: videoTrack)) {
                subscriptionManager.unprojectVideo(for: source)
                await stateMachine.setPlayingVideo(false, for: source)
            }
        default:
            return
        }
    }
}

// MARK: SubscriptionManagerDelegate implementation

extension StreamCoordinator: SubscriptionManagerDelegate {
    public func onSubscribedError(_ reason: String) {
        Task {
            await stateMachine.onSubscribedError(reason)
        }
    }

    public func onSignalingError(_ message: String) {
        Task {
            await stateMachine.onSignalingError(message)
        }
    }

    public func onConnectionError(_ status: Int32, withReason reason: String) {
        Task {
            await stateMachine.onConnectionError(status, withReason: reason)
            if Self.configuration.retryOnConnectionError {
                taskScheduler.scheduleTask(timeInterval: Self.configuration.retryTimeInterval) { [weak self] in
                    guard let self = self else { return }
                    Task {
                        switch await self.stateMachine.currentState {
                        case let .error(state):
                            switch state.error {
                            case .connectFailed:
                                self.taskScheduler.invalidate()
                                _ = await self.connect(streamName: state.streamDetail.streamName, accountID: state.streamDetail.accountID)
                            default:
                                break
                            }
                        default:
                            break
                        }
                    }
                }
            }
        }
    }

    public func onStopped() {
        Task {
            await stateMachine.onStopped()
        }
    }

    public func onConnected() {
        Task {
            await stateMachine.onConnected()
            if Self.configuration.subscribeOnSuccessfulConnection {
                _ = await startSubscribe()
            }
        }
    }

    public func onSubscribed() {
        Task {
            await stateMachine.onSubscribed()
        }
    }

    public func onVideoTrack(_ track: MCVideoTrack, withMid mid: String) {
        Task { [weak self] in
            guard let self = self else {
                return
            }
            await self.stateMachine.onVideoTrack(track, withMid: mid)
        }
    }

    public func onAudioTrack(_ track: MCAudioTrack, withMid mid: String) {
        Task {
            await stateMachine.onAudioTrack(track, withMid: mid)
        }
    }

    public func onStatsReport(_ report: MCStatsReport) {
        guard let streamingStats = StreamingStatistics(report) else {
            return
        }
        Task {
            await stateMachine.onStatsReport(streamingStats)
        }
    }

    public func onViewerCount(_ count: Int32) {
        Task {
            await stateMachine.updateNumberOfStreamViewers(count)
        }
    }

    public func onLayers(_ mid_: String, activeLayers: [MCLayerData], inactiveLayers: [MCLayerData]) {
        Task {
            await stateMachine.onLayers(mid_, activeLayers: activeLayers, inactiveLayers: inactiveLayers)
        }
    }

    public func onActive(_ streamId: String, tracks: [String], sourceId: String?) {
        Task {
            await stateMachine.onActive(streamId, tracks: tracks, sourceId: sourceId)
            let stateMachineState = await stateMachine.currentState
            switch stateMachineState {
            case let .subscribed(state):
                guard let sourceBuilder = state.streamSourceBuilders.first(where: { $0.sourceId.value == sourceId }) else {
                    return
                }
                subscriptionManager.addRemoteTrack(sourceBuilder)
            default:
                return
            }
        }
    }

    public func onInactive(_ streamId: String, sourceId: String?) {
        Task { [weak self] in
            guard let self = self else {
                return
            }
            await self.stateMachine.onInactive(streamId, sourceId: sourceId)
        }
    }
}

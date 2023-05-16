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
    private let rendererManager: RendererManagerProtocol
    private let taskScheduler: TaskSchedulerProtocol

    private static var configuration: StreamCoordinatorConfiguration = .init()

    private var subscriptions: Set<AnyCancellable> = []
    private lazy var stateSubject: CurrentValueSubject<StreamState, Never> = CurrentValueSubject(.disconnected)
    public lazy var statePublisher: AnyPublisher<StreamState, Never> = stateSubject.eraseToAnyPublisher()

    private init() {
        subscriptionManager = SubscriptionManager()
        taskScheduler = TaskScheduler()
        rendererManager = RendererManager()

        subscriptionManager.delegate = self

        startStateObservation()
    }

    #if DEBUG
    init(subscriptionManager: SubscriptionManagerProtocol, taskScheduler: TaskSchedulerProtocol, rendererManager: RendererManagerProtocol) {
        self.subscriptionManager = subscriptionManager
        self.taskScheduler = taskScheduler
        self.rendererManager = rendererManager

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
        return await subscriptionManager.connect(streamName: streamName, accountID: accountID)
    }

    public func startSubscribe() async -> Bool {
        await stateMachine.startSubscribe()
        return await subscriptionManager.startSubscribe()
    }

    public func stopSubscribe() async -> Bool {
        await stateMachine.stopSubscribe()
        rendererManager.reset()
        return await subscriptionManager.stopSubscribe()
    }

    public func selectVideoQuality(_ quality: StreamSource.VideoQuality, for source: StreamSource) {
        subscriptionManager.selectVideoQuality(quality, for: source)
    }

    public func playAudio(for source: StreamSource) {
        switch stateSubject.value {
        case let .subscribed(sources: sources, numberOfStreamViewers: _):
            sources.forEach { source in
                if source.isPlayingAudio {
                    subscriptionManager.unprojectAudio(for: source)
                }
            }
            subscriptionManager.projectAudio(for: source)

        default:
            return
        }
    }

    public func stopAudio(for source: StreamSource) {
        subscriptionManager.unprojectAudio(for: source)
    }

    public func playVideo(for source: StreamSource, quality: StreamSource.VideoQuality) {
        subscriptionManager.projectVideo(for: source, withQuality: quality)
    }

    public func stopVideo(for source: StreamSource) {
        subscriptionManager.unprojectVideo(for: source)
    }

    public func mainSourceViewProvider(for source: StreamSource) -> SourceViewProviding? {
        rendererManager.mainRenderer(for: source.sourceId).map { StreamSourceViewProvider(renderer: $0) }
    }

    public func subSourceViewProvider(for source: StreamSource) -> SourceViewProviding? {
        rendererManager.subRenderer(for: source.sourceId).map { StreamSourceViewProvider(renderer: $0) }
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

            // Add Video Renderer for Video Track
            switch await self.stateMachine.currentState {
            case let .subscribed(state):
                if let builder = state.streamSourceBuilders.first(where: { $0.videoTrack?.trackInfo.mid == mid }) {
                    await self.rendererManager.addRenderer(sourceId: builder.sourceId, track: track)
                }
            default:
                break
            }
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
            // Remove Video Renderer for Video Track
            let streamSourceId: StreamSource.SourceId?
            switch await self.stateMachine.currentState {
            case let .subscribed(state):
                let builder = state.streamSourceBuilders.first(where: { $0.sourceId.value == sourceId })
                streamSourceId = builder?.sourceId
            default:
                streamSourceId = nil
            }

            await stateMachine.onInactive(streamId, sourceId: sourceId)
            streamSourceId.map { self.rendererManager.removeRenderer(sourceId: $0) }
        }
    }
}

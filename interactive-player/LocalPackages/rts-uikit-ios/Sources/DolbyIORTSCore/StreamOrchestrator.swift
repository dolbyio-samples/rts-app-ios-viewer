//
//  StreamOrchestrator.swift
//

import Combine
import Foundation
import MillicastSDK
import os

@globalActor
public final actor StreamOrchestrator {

    private static let logger = Logger.make(category: String(describing: StreamOrchestrator.self))

    private enum Defaults {
        static let retryConnectionTimeInterval = 5.0
    }

    public static let shared: StreamOrchestrator = StreamOrchestrator()

    private let stateMachine: StateMachine = StateMachine(initialState: .disconnected)

    private var subscriptions: Set<AnyCancellable> = []
    private lazy var stateSubject: CurrentValueSubject<StreamState, Never> = CurrentValueSubject(.disconnected)
    public lazy var statePublisher: AnyPublisher<StreamState, Never> = stateSubject
        .removeDuplicates()
        .eraseToAnyPublisher()
    private var activeStreamDetail: StreamDetail?
    private let logHandler: MillicastLoggerHandler = .init()

    private var rendererRegistry: RendererRegistryProtocol?
    private var subscriptionManager: SubscriptionManagerProtocol?
    private var subscriptionConfiguration: SubscriptionConfiguration?

    private var stateObservationTask: Task<Void, Error>?
    private var statsObservationTask: Task<Void, Error>?
    private var activityObservationTask: Task<Void, Error>?
    private var tracksObservationTask: Task<Void, Error>?
    private var layersObservationTask: Task<Void, Error>?
    private var viewerObservationTask: Task<Void, Error>?

    init() {
        Utils.configureAudioSession()

        Task { [weak self] in
            guard let self = self else { return }
            await self.startStateObservation()
        }
    }

    public func connect(streamName: String, accountID: String, configuration: SubscriptionConfiguration = .init()) async throws -> Bool {
        Self.logger.debug("👮‍♂️ Start subscribe")
        logHandler.setLogFilePath(filePath: configuration.sdkLogPath)
        let subscriptionManager = SubscriptionManager(configuration: configuration)

        self.observeSubscriptionManagerEvents()
        self.subscriptionManager = subscriptionManager
        self.subscriptionConfiguration = configuration
        self.rendererRegistry = RendererRegistry()

        async let startConnectionStateUpdate: Void = stateMachine.startConnection(
            streamName: streamName,
            accountID: accountID,
            configuration: configuration
        )
        async let startConnection = subscriptionManager.connect(streamName: streamName, accountID: accountID)

        let (_, connectionResult) = try await (startConnectionStateUpdate, startConnection)
        if connectionResult {
            activeStreamDetail = StreamDetail(streamName: streamName, accountID: accountID)
        } else {
            activeStreamDetail = nil
        }

        stateMachine.onConnected()

        let subscribeResult = try await subscriptionManager.subscribe()

        stateMachine.onSubscribed()

        return subscribeResult
    }

    public func stopConnection() async throws -> Bool {
        Self.logger.debug("👮‍♂️ Stop subscribe")

        async let stopSubscribeOnStateMachine: Void = stateMachine.stopSubscribe()
        async let resetRegistry: Void? = rendererRegistry?.reset()
        async let stopSubscription: Bool? = await subscriptionManager?.unubscribeAndDisconnect()
        let (_, _, stopSubscribeResult) = try await (stopSubscribeOnStateMachine, resetRegistry, stopSubscription)

        reset()
        return stopSubscribeResult ?? false
    }

    public func playAudio(for source: StreamSource) async throws {
        Self.logger.debug("👮‍♂️ Play Audio for source - \(String(describing: source.sourceId.value))")
        guard let subscriptionManager else { return }

        switch stateMachine.currentState {
        case let .subscribed(subscribedState):
            guard
                let matchingSource = subscribedState.sources.first(where: { $0.id == source.id }),
                !matchingSource.isPlayingAudio
            else {
                return
            }

            await withThrowingTaskGroup(of: Void.self) { [self] group in
                for source in subscribedState.sources {
                    guard source.isPlayingAudio else {
                        continue
                    }

                    group.addTask {
                        self.stateMachine.setPlayingAudio(false, for: source)
                        try await subscriptionManager.unprojectAudio(for: source)
                    }
                }

                group.addTask {
                    try await subscriptionManager.projectAudio(for: source)
                    self.stateMachine.setPlayingAudio(true, for: source)
                }
            }

        default:
            return
        }
    }

    public func stopAudio(for source: StreamSource) async throws {
        Self.logger.debug("👮‍♂️ Stop Audio for source - \(String(describing: source.sourceId.value))")
        guard let subscriptionManager else { return }

        switch stateMachine.currentState {
        case let .subscribed(subscribedState):
            guard
                let matchingSource = subscribedState.sources.first(where: { $0.id == source.id }),
                matchingSource.isPlayingAudio
            else {
                return
            }
            try await subscriptionManager.unprojectAudio(for: matchingSource)
            stateMachine.setPlayingAudio(false, for: matchingSource)

        default:
            return
        }
    }

    public func playVideo(for source: StreamSource, on renderer: StreamSourceViewRenderer, with quality: VideoQuality) async throws {
        Self.logger.debug("👮‍♂️ Play Video for source - \(String(describing: source.sourceId.value)) on renderer - \(renderer.id) with quality - \(quality.description)")
        guard let subscriptionManager, let rendererRegistry else { return }

        switch stateMachine.currentState {
        case let .subscribed(subscribedState):
            guard
                let matchingSource = subscribedState.sources.first(where: { $0.id == source.id })
            else {
                return
            }
            let videoTrack = matchingSource.videoTrack.track
            rendererRegistry.registerRenderer(renderer, with: quality)
            let requestedVideoQuality = rendererRegistry.requestedVideoQuality(for: videoTrack)
            let videoQualityToRender = matchingSource.videoQualityList.contains(requestedVideoQuality) ? requestedVideoQuality : .auto

            if !matchingSource.isPlayingVideo || matchingSource.selectedVideoQuality != videoQualityToRender {
                try await subscriptionManager.projectVideo(for: matchingSource, withQuality: videoQualityToRender)
                stateMachine.setPlayingVideo(true, for: matchingSource)
                stateMachine.selectVideoQuality(videoQualityToRender, for: matchingSource)
            }

        default:
            return
        }
    }

    public func stopVideo(for source: StreamSource, on renderer: StreamSourceViewRenderer) async throws {
        Self.logger.debug("👮‍♂️ Stop Video for source - \(String(describing: source.sourceId.value)) on renderer - \(renderer.id)")
        guard let subscriptionManager, let rendererRegistry else { return }

        switch stateMachine.currentState {
        case let .subscribed(subscribedState):
            guard
                let matchingSource = subscribedState.sources.first(where: { $0.id == source.id }),
                matchingSource.isPlayingVideo
            else {
                return
            }
            let videoTrack = matchingSource.videoTrack.track
            rendererRegistry.deregisterRenderer(renderer)

            let hasActiveRenderer = rendererRegistry.hasActiveRenderer(for: videoTrack)
            if !hasActiveRenderer {
                try await subscriptionManager.unprojectVideo(for: source)
                stateMachine.setPlayingVideo(false, for: matchingSource)
                stateMachine.onLayers(
                    matchingSource.videoTrack.trackInfo.mid,
                    activeLayers: [],
                    inactiveLayers: []
                )
            } else {
                let requestedVideoQuality = rendererRegistry.requestedVideoQuality(for: videoTrack)
                let videoQualityToRender = matchingSource.videoQualityList.contains(requestedVideoQuality) ? requestedVideoQuality : .auto

                if matchingSource.selectedVideoQuality != videoQualityToRender {
                    try await subscriptionManager.projectVideo(for: matchingSource, withQuality: videoQualityToRender)
                    stateMachine.setPlayingVideo(true, for: matchingSource)
                    stateMachine.selectVideoQuality(videoQualityToRender, for: matchingSource)
                }
            }

        default:
            return
        }
    }
}

// MARK: Private helper methods

private extension StreamOrchestrator {
    func startStateObservation() {
        stateMachine.statePublisher
            .sink { state in
                Task { [weak self] in
                    guard let self = self else { return }
                    // Populate updates public facing states
                    let streamState = StreamState(state: state)
                    await self.stateSubject.send(streamState)
                }
            }
            .store(in: &subscriptions)
    }

    func reconnectToStream(streamDetail: StreamDetail) async throws {
        Self.logger.debug("👮‍♂️ Attempting a reconnect")
        _ = try await connect(streamName: streamDetail.streamName, accountID: streamDetail.accountID)
    }

    func stopAudio(for sourceId: String?) async throws {
        guard let subscriptionManager else { return }
        switch stateSubject.value {
        case let .subscribed(sources: sources, numberOfStreamViewers: _):
            if let source = sources.first(where: { $0.sourceId == StreamSource.SourceId(id: sourceId) }), source.isPlayingAudio {
                try await subscriptionManager.unprojectAudio(for: source)
            }
        default: break
        }
    }

    func reset() {
        activeStreamDetail = nil
        logHandler.setLogFilePath(filePath: nil)
        subscriptionConfiguration = nil
        subscriptionManager = nil
        rendererRegistry = nil

        stateObservationTask?.cancel()
        stateObservationTask = nil

        statsObservationTask?.cancel()
        statsObservationTask = nil
    }
}

// MARK: SubscriptionManagerDelegate implementation

extension StreamOrchestrator {

    // swiftlint:disable cyclomatic_complexity function_body_length
    func observeSubscriptionManagerEvents() {
        Task {
            self.stateObservationTask = Task { @StreamOrchestrator [weak self] in
                guard let self, let subscriptionManager = await self.subscriptionManager else { return }
                for await state in subscriptionManager.state {
                    switch state {
                    case .connected:
                        Self.logger.debug("🔥 Event (state): connected")
                        self.stateMachine.onConnected()

                    case .disconnected:
                        Self.logger.debug("🔥 Event (state): disconnected")
                        self.stateMachine.onDisconnected()

                    case let .connectionError(status: status, reason: reason):
                        Self.logger.debug("🔥 Event (state): connectionError status:\(status), reason: \(reason)")
                        self.stateMachine.onConnectionError(status, withReason: reason)

                    case .subscribed:
                        Self.logger.debug("🔥 Event (state): subscribed")
                        self.stateMachine.onSubscribed()

                    case let .signalingError(reason: reason):
                        Self.logger.debug("🔥 Event (state): signalingError reason: \(reason)")
                        self.stateMachine.onSignalingError(reason)
                    }

                }
            }

            self.viewerObservationTask = Task { @StreamOrchestrator [weak self] in
                guard let self, let subscriptionManager = await self.subscriptionManager else { return }
                for await viewerCount in subscriptionManager.viewerCount {
                    Self.logger.debug("🔥 Event (viewerCount): \(viewerCount)")
                    self.stateMachine.updateNumberOfStreamViewers(viewerCount)
                }
            }

            self.activityObservationTask = Task { @StreamOrchestrator [weak self] in
                guard let self, let subscriptionManager = await self.subscriptionManager else { return }
                for await activity in subscriptionManager.activityStream {
                    switch activity {
                    case let .active(streamId: streamId, tracks: tracks, sourceId: sourceId):
                        Self.logger.debug("🔥 Event (activityStream): active with streamId:\(streamId), tracks:\(tracks), sourceId: \(sourceId)")
                        self.stateMachine.onActive(streamId, tracks: tracks, sourceId: sourceId)
                        let stateMachineState = self.stateMachine.currentState
                        switch stateMachineState {
                        case let .subscribed(state):
                            guard  let sourceBuilder = state.streamSourceBuilders.first(where: { $0.sourceId == StreamSource.SourceId(id: sourceId) }) else {
                                return
                            }
                            await subscriptionManager.addRemoteTrack(sourceBuilder)

                        default:
                            return
                        }

                    case let .inactive(streamId: streamId, sourceId: sourceId):
                        Self.logger.debug("🔥 Event (activityStream): inactive with streamId:\(streamId), sourceId: \(sourceId)")
                        // Unproject audio whose source is inactive
                        try await self.stopAudio(for: sourceId)

                        self.stateMachine.onInactive(streamId, sourceId: sourceId)
                    }
                }
            }

            self.tracksObservationTask = Task { @StreamOrchestrator [weak self] in
                guard let self, let subscriptionManager = await self.subscriptionManager else { return }

                for await trackEvent in subscriptionManager.tracks {
                    switch trackEvent {
                    case let .audio(track: track, mid: mid):
                        Self.logger.debug("🔥 Event (tracks): audio track: \(track), mid: \(mid)")
                        self.stateMachine.onAudioTrack(track, withMid: mid)

                    case let .video(track: track, mid: mid):
                        Self.logger.debug("🔥 Event (tracks): video track: \(track), mid: \(mid)")
                        self.stateMachine.onVideoTrack(track, withMid: mid)
                    }
                }
            }

            self.layersObservationTask = Task { @StreamOrchestrator [weak self] in
                guard let self, let subscriptionManager = await self.subscriptionManager else { return }

                for await layerEvent in subscriptionManager.layers {
                    Self.logger.debug("🔥 Event (layers): onLayers with mid: \(layerEvent.mid), activeLayers: \(layerEvent.activeLayers)")
                    self.stateMachine.onLayers(layerEvent.mid, activeLayers: layerEvent.activeLayers, inactiveLayers: layerEvent.inactiveLayers)
                }
            }

            self.statsObservationTask = Task { @StreamOrchestrator [weak self] in
                guard let self, let subscriptionManager = await self.subscriptionManager else { return }
                for await stats in subscriptionManager.statsReport {
                    guard let streamingStats = AllStreamStatistics(stats) else { return }
                    Self.logger.debug("🔥 Event (statsReport)")
                    self.stateMachine.onStatsReport(streamingStats)
                }
            }

            _ = try await [
                self.stateObservationTask?.value,
                self.tracksObservationTask?.value,
                self.activityObservationTask?.value,
                self.layersObservationTask?.value,
                self.statsObservationTask?.value,
                self.viewerObservationTask?.value
            ]
        }
    }
    // swiftlint:enable cyclomatic_complexity function_body_length
}

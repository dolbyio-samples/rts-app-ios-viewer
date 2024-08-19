//
//  StreamViewModel.swift
//

import Combine
import RTSCore
import Foundation
import MillicastSDK
import os

@MainActor
final class StreamViewModel: ObservableObject {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: StreamViewModel.self)
    )

    enum DisplayMode: Equatable {
        case single
        case list
        case grid
    }

    enum State {
        case loading
        case success(
            displayMode: DisplayMode,
            sources: [StreamSource],
            selectedVideoSource: StreamSource,
            selectedAudioSource: StreamSource?,
            settings: StreamSettings
        )
        case error(title: String, subtitle: String?)
    }

    let subscriptionManager: SubscriptionManager
    let videoTracksManager: VideoTracksManager

    private let settingsManager: SettingsManager
    private var subscriptions: [AnyCancellable] = []
    private var reconnectionTimer: Timer?
    private var isWebsocketConnected: Bool = false

    let streamDetail: StreamDetail
    let settingsMode: SettingsMode
    let configuration: SubscriptionConfiguration
    let listViewPrimaryVideoQuality: VideoQuality
    let serialTasks = SerialTasks()

    @Published private(set) var state: State = .loading {
        didSet {
            // Play Audio when the selectedAudioSource changes
            if let newlySelectedAudioSource = state.selectedAudioSource, newlySelectedAudioSource.id != oldValue.selectedAudioSource?.id {
                if let previouslySelectedAudioSource = oldValue.selectedAudioSource {
                    stopAudio(for: previouslySelectedAudioSource)
                }
                playAudio(for: newlySelectedAudioSource)
            }

            // Stop PiP when there is no video streams
            if !state.isShowingVideoStreams {
                stopPiP()
            }
        }
    }

    init(
        context: StreamingView.Context,
        settingsManager: SettingsManager = .shared,
        videoTracksManager: VideoTracksManager = VideoTracksManager(),
        subscriptionManager: SubscriptionManager = SubscriptionManager()
    ) {
        self.subscriptionManager = subscriptionManager
        self.settingsManager = settingsManager
        self.streamDetail = context.streamDetail
        self.configuration = context.configuration
        self.listViewPrimaryVideoQuality = context.listViewPrimaryVideoQuality
        self.settingsMode = .stream(streamName: streamDetail.streamName, accountID: streamDetail.accountID)
        self.videoTracksManager = videoTracksManager

        startObservers()
    }

    func selectVideoSource(_ source: StreamSource) {
        switch state {
        case let .success(
            displayMode: displayMode,
            sources: sources,
            selectedVideoSource: _,
            selectedAudioSource: _,
            settings: settings
        ):
            guard let matchingVideoSource = sources.first(where: { $0.id == source.id }) else {
                fatalError("Cannot select source thats not part of the current source list")
            }

            let selectedAudioSource = audioSelection(from: sources, settings: settings, selectedVideoSource: matchingVideoSource)

            let updatedState: State = .success(
                displayMode: displayMode,
                sources: sources,
                selectedVideoSource: matchingVideoSource,
                selectedAudioSource: selectedAudioSource,
                settings: settings
            )
            update(state: updatedState)
        default:
            fatalError("Cannot select source when the state is not `.success`")
        }
    }

    @objc
    func viewStream() {
        Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            _ = try await self.subscriptionManager.subscribe(
                streamName: self.streamDetail.streamName,
                accountID: self.streamDetail.accountID,
                configuration: self.configuration
            )
        }
    }

    func endStream() {
        Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            self.subscriptions.removeAll()
            self.reconnectionTimer?.invalidate()
            self.reconnectionTimer = nil
            await self.videoTracksManager.reset()
            _ = try await self.subscriptionManager.unSubscribe()
        }
    }

    func scheduleReconnection() {
        Self.logger.debug("🎰 Schedule reconnection")
        reconnectionTimer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(viewStream), userInfo: nil, repeats: false)
    }

    private func playAudio(for source: StreamSource) {
        Task {
            Self.logger.debug("🎰 Enabling audio for source \(source.sourceId)")
            try await source.audioTrack?.enable()
        }
    }

    private func stopAudio(for source: StreamSource) {
        Task {
            try await source.audioTrack?.disable()
        }
    }

    private func update(state: State) {
        self.state = state
    }

    private func makeState(from sources: [StreamSource], settings: StreamSettings) -> State? {
        guard !sources.isEmpty else {
            Self.logger.debug("🎰 Sources list is empty")
            return nil
        }

        Self.logger.debug("🎰 Make state for \(sources.map({ $0.sourceId.description }).joined(separator: ", "))")

        let sortedSources: [StreamSource]
        switch settings.streamSortOrder {
        case .connectionOrder:
            sortedSources = sources
        case .alphaNumeric:
            sortedSources = sources.sorted { $0 < $1 }
        }

        let selectedVideoSource: StreamSource

        switch state {
        case .error, .loading:
            selectedVideoSource = sortedSources[0]

        case let .success(
            displayMode: _,
            sources: _,
            selectedVideoSource: currentlySelectedVideoSource,
            selectedAudioSource: _,
            settings: _
        ):
            selectedVideoSource = sources.first { $0.id == currentlySelectedVideoSource.id } ?? sortedSources[0]
        }

        let selectedAudioSource = audioSelection(from: sources, settings: settings, selectedVideoSource: selectedVideoSource)

        let displayMode: DisplayMode = switch settings.multiviewLayout {
        case .list:
            .list
        case .grid:
            .grid
        case .single:
            .single
        }

        return .success(
            displayMode: displayMode,
            sources: sortedSources,
            selectedVideoSource: selectedVideoSource,
            selectedAudioSource: selectedAudioSource,
            settings: settings
        )
    }

    private func updateAudioSourceListing(for sources: [StreamSource], currentSettings: StreamSettings) {
        // Only update the settings when the sources change, only sources with at least one audio track
        let sourceIdsWithActiveAudioTrack = sources
            .filter { $0.audioTrack != nil && $0.audioTrack?.isActive == true }
            .compactMap { $0.sourceId.value }

        if sourceIdsWithActiveAudioTrack != currentSettings.audioSources {
            var updatedSettings = currentSettings
            updatedSettings.audioSources = sourceIdsWithActiveAudioTrack

            // If source selected in settings is no longer available, update the settings
            if case let .source(sourceId) = currentSettings.audioSelection, !currentSettings.audioSources.contains(sourceId) {
                updatedSettings.audioSelection = .firstSource
            }

            settingsManager.update(settings: updatedSettings, for: settingsMode)
        }
    }

    private func audioSelection(from sources: [StreamSource], settings: StreamSettings, selectedVideoSource: StreamSource) -> StreamSource? {
        // Get the sources with at least one audio track if none, uses the original sources list
        let sourcesWithAudio = sources.filter { $0.audioTrack != nil }
        if sourcesWithAudio.isEmpty {
            return nil
        }
        let selectedAudioSource: StreamSource?
        switch settings.audioSelection {
        case .firstSource:
            selectedAudioSource = sourcesWithAudio.first
        case .mainSource:
            // If no main source available, use first source as main
            selectedAudioSource = sourcesWithAudio
                .first(where: { $0.sourceId == .main }) ?? sourcesWithAudio.first
        case .followVideo:
            // Use audio from the video source, if no audio track uses the last one used or just the 1st one
            if selectedVideoSource.audioTrack != nil {
                selectedAudioSource = selectedVideoSource
            } else {
                // Fallback to last used audio or else the first in the list
                selectedAudioSource = state.selectedAudioSource ?? sourcesWithAudio.first
            }
        case let .source(sourceId: sourceId):
            selectedAudioSource = sourcesWithAudio
                .first { $0.sourceId == SourceID(sourceId: sourceId) } ?? sourcesWithAudio.first
        }
        return selectedAudioSource
    }

    private func stopPiP() {
        PiPManager.shared.stopPiP()
    }
}

private extension StreamViewModel {
    // swiftlint:disable function_body_length cyclomatic_complexity
    func startObservers() {
        Task { [weak self] in
            guard let self else { return }
            let settingsPublisher = self.settingsManager.publisher(for: settingsMode)
            let statePublisher = await self.subscriptionManager.$state

            Publishers.CombineLatest(statePublisher, settingsPublisher)
                .sink { state, settings in
                    Self.logger.debug("🎰 State and settings events")
                    Task {
                        try await self.serialTasks.enqueue {
                            switch state {
                            case let .subscribed(sources: sources):
                                let activeSources = Array(sources.filter { $0.videoTrack.isActive == true })

                                // Register Video Track events
                                await withTaskGroup(of: Void.self) { group in
                                    for source in activeSources {
                                        group.addTask {
                                            await self.videoTracksManager.observeLayerUpdates(for: source)
                                        }
                                    }
                                }
                                guard !Task.isCancelled else { return }

                                await self.updateAudioSourceListing(for: activeSources, currentSettings: settings)
                                guard let newState = await self.makeState(from: activeSources, settings: settings) else {
                                    Self.logger.debug("🎰 Make state returned without a value")
                                    await self.update(state: .error(title: .offlineErrorTitle, subtitle: .offlineErrorSubtitle))
                                    return
                                }
                                await self.update(state: newState)

                            case .disconnected:
                                Self.logger.debug("🎰 Stream disconnected")
                                await self.update(state: .loading)

                            case let .error(connectionError) where connectionError.status == 0:
                                // Status code `0` represents a `no network error`
                                Self.logger.debug("🎰 No internet connection")
                                if await !self.isWebsocketConnected {
                                    await self.scheduleReconnection()
                                }
                                await self.update(state: .error(title: .noInternetErrorTitle, subtitle: nil))

                            case let .error(connectionError):
                                Self.logger.debug("🎰 Connection error - \(connectionError.status), \(connectionError.reason)")
                                if await !self.isWebsocketConnected {
                                    await self.scheduleReconnection()
                                }
                                await self.update(state: .error(title: .offlineErrorTitle, subtitle: .offlineErrorSubtitle))
                            }
                        }
                    }
                }
                .store(in: &subscriptions)

            await self.subscriptionManager.$websocketState
                .sink { websocketState in
                    switch websocketState {
                    case .connected:
                        self.isWebsocketConnected = true
                    default:
                        break
                    }
                }
                .store(in: &subscriptions)
        }
    }
    // swiftlint:enable function_body_length cyclomatic_complexity
}

fileprivate extension StreamViewModel.State {
    var selectedAudioSource: StreamSource? {
        return switch self {
        case let .success(
            displayMode: _,
            sources: _,
            selectedVideoSource: _,
            selectedAudioSource: currentlySelectedAudioSource,
            settings: _
        ):
            currentlySelectedAudioSource
        default:
            nil
        }
    }

    var isShowingVideoStreams: Bool {
        switch self {
        case let .success(
            displayMode: _,
            sources: sources,
            selectedVideoSource: _,
            selectedAudioSource: _,
            settings: _
        ):
            return !sources.isEmpty
        default:
            return false
        }
    }
}

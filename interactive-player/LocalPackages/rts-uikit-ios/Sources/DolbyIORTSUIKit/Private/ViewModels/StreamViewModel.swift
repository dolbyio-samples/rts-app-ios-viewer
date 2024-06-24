//
//  StreamViewModel.swift
//

import Combine
import DolbyIORTSCore
import Foundation
import MillicastSDK
import os

@MainActor
final class StreamViewModel: ObservableObject {
    private static let logger = Logger(
        subsystem: Bundle.module.bundleIdentifier!,
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

    private var audioTrackActivityObservationDictionary: [SourceID: Task<Void, Never>] = [:]

    let streamDetail: StreamDetail
    let settingsMode: SettingsMode
    let listViewPrimaryVideoQuality: VideoQuality

    private let trackActiveStateUpdateSubject: CurrentValueSubject<Void, Never> = CurrentValueSubject(())

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
        videoTracksManager: VideoTracksManager = VideoTracksManager()
    ) {
        self.subscriptionManager = context.subscriptionManager
        self.settingsManager = settingsManager
        self.streamDetail = context.streamDetail
        self.listViewPrimaryVideoQuality = context.listViewPrimaryVideoQuality
        self.settingsMode = .stream(streamName: streamDetail.streamName, accountID: streamDetail.accountID)
        self.videoTracksManager = videoTracksManager

        Task {
            await videoTracksManager.setTrackStateUpdateSubject(trackActiveStateUpdateSubject)
        }
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

    func endStream() async throws {
        _ = try await subscriptionManager.unSubscribe()
        subscriptions.removeAll()
        audioTrackActivityObservationDictionary.removeAll()
        await videoTracksManager.reset()
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

    private func updateStreamSettings(from sources: [StreamSource], settings: StreamSettings) {
        // Only update the settings when the sources change, only sources with at least one audio track
        let sourceIdsWithActiveAudioTrack = sources
            .filter { $0.audioTrack != nil && $0.audioTrack?.isActive == true }
            .compactMap { $0.sourceId.value }

        if sourceIdsWithActiveAudioTrack != settings.audioSources {
            var updatedSettings = settings
            updatedSettings.audioSources = sourceIdsWithActiveAudioTrack

            // If source selected in settings is no longer available, update the settings
            if case let .source(sourceId) = settings.audioSelection, !settings.audioSources.contains(sourceId) {
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
    func startObservers() {

        Task { [weak self] in
            guard let self else { return }
            let settingsPublisher = settingsManager.publisher(for: settingsMode)
            let statePublisher = await subscriptionManager.$state

            Publishers.CombineLatest3(statePublisher, settingsPublisher,
                                      trackActiveStateUpdateSubject)
                .sink { state, settings, _ in
                    Self.logger.debug("🎰 State and settings events")
                    Task {
                        switch state {
                        case let .subscribed(sources: sources):
                            let activeSources = Array(sources.filter { $0.videoTrack.isActive == true })

                            // Register Video Track events
                            await withTaskGroup(of: Void.self) { group in
                                for source in activeSources {
                                    group.addTask {
                                        await self.observeAudioTrackEvents(for: source)
                                        await self.videoTracksManager.observeVideoTrackEvents(for: source)
                                    }
                                }
                            }

                            self.updateStreamSettings(from: activeSources, settings: settings)
                            guard let newState = self.makeState(from: activeSources, settings: settings) else {
                                Self.logger.debug("🎰 Make state returned without a value")
                                return
                            }
                            self.update(state: newState)

                        case .disconnected:
                            Self.logger.debug("🎰 Stream disconnected")
                            self.update(state: .loading)

                        case .stopped:
                            Self.logger.debug("🎰 Stream stopped")
                            self.update(state: .error(title: .offlineErrorTitle, subtitle: .offlineErrorSubtitle))

                        case .error(.connectError(status: 0, reason: _)):
                            // Status code `0` represents a `no network error`
                            Self.logger.debug("🎰 No internet connection")
                            self.update(state: .error(title: .noInternetErrorTitle, subtitle: nil))

                        case let .error(.connectError(status: status, reason: reason)):
                            Self.logger.debug("🎰 Connection error - \(status), \(reason)")
                            self.update(state: .error(title: .offlineErrorTitle, subtitle: .offlineErrorSubtitle))

                        case let .error(.signalingError(reason: reason)):
                            Self.logger.debug("🎰 Signaling error - \(reason)")
                            self.update(state: .error(title: .genericErrorTitle, subtitle: nil))
                        }
                    }
                }
                .store(in: &subscriptions)
        }
    }

    func observeAudioTrackEvents(for source: StreamSource) {
        Task { [weak self] in
            guard
                let self,
                let audioTrack = source.audioTrack,
                self.audioTrackActivityObservationDictionary[source.sourceId] == nil
            else {
                return
            }

            Self.logger.debug("🎤 Registering for audio track lifecycle events of \(source.sourceId)")
            let audioTrackActivityObservation = Task {
                for await activityEvent in audioTrack.activity() {
                    switch activityEvent {
                    case .active:
                        Self.logger.debug("🎤 Audio track for \(source.sourceId) is active")
                        self.trackActiveStateUpdateSubject.send()

                    case .inactive:
                        Self.logger.debug("🎤 Audio track for \(source.sourceId) is inactive")
                        self.trackActiveStateUpdateSubject.send()
                    }
                }
            }
            self.audioTrackActivityObservationDictionary[source.sourceId] = audioTrackActivityObservation

            await audioTrackActivityObservation.value
        }
    }

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

//
//  StreamViewModel.swift
//

import Combine
import DolbyIORTSCore
import Foundation

// swiftlint:disable type_body_length
final class StreamViewModel: ObservableObject {

    enum State {
        case loading
        case success(displayMode: DisplayMode)
        case error(title: String, subtitle: String)

        fileprivate init(_ state: InternalState) {
            switch state {
            case .loading:
                self = .loading
            case let .success(
                displayMode: displayMode,
                sources: _,
                selectedVideoSource: _,
                selectedAudioSource: _,
                sourceAndViewRenderers: _,
                detailSourceAndViewRenderers: _,
                settings: _
            ):
                self = .success(displayMode: displayMode)
            case let .error(title: title, subtitle: subtitle):
                self = .error(title: title, subtitle: subtitle)
            }
        }
    }

    fileprivate enum InternalState {
        case loading
        case success(
            displayMode: DisplayMode,
            sources: [StreamSource],
            selectedVideoSource: StreamSource,
            selectedAudioSource: StreamSource,
            sourceAndViewRenderers: StreamSourceAndViewRenderers,
            detailSourceAndViewRenderers: StreamSourceAndViewRenderers,
            settings: StreamSettings
        )
        case error(title: String, subtitle: String)
    }

    enum DisplayMode {
        case single(SingleStreamViewModel)
        case list(ListViewModel)
    }

    private let settingsManager: SettingsManager
    private let streamCoordinator: StreamCoordinator
    private var subscriptions: [AnyCancellable] = []

    let streamDetail: StreamDetail?

    @Published private(set) var state: State = .loading

    private var internalState: InternalState = .loading {
        didSet {
            state = State(internalState)

            // Play Audio when the selectedAudioSource changes
            if let newlySelectedAudioSource = internalState.selectedAudioSource,
               newlySelectedAudioSource.id != oldValue.selectedAudioSource?.id {
                playAudio(for: newlySelectedAudioSource)
            }
        }
    }

    private var sources: [StreamSource] {
        switch internalState {
        case let .success(
            displayMode: _,
            sources: existingSources,
            selectedVideoSource: _,
            selectedAudioSource: _,
            sourceAndViewRenderers: _,
            detailSourceAndViewRenderers: _,
            settings: _
        ):
            return existingSources
        default:
            return []
        }
    }

    init(
        streamCoordinator: StreamCoordinator = .shared,
        settingsManager: SettingsManager = .shared
    ) {
        self.streamCoordinator = streamCoordinator
        self.settingsManager = settingsManager
        self.streamDetail = streamCoordinator.activeStreamDetail
        if let streamId = streamCoordinator.activeStreamDetail?.streamId {
            settingsManager.setActiveSetting(for: .stream(streamID: streamId))
        }

        startObservers()
    }

    var detailSingleStreamViewModel: SingleStreamViewModel? {
        switch internalState {
        case let .success(
            displayMode: _,
            sources: sources,
            selectedVideoSource: selectedVideoSource,
            selectedAudioSource: selectedAudioSource,
            sourceAndViewRenderers: _,
            detailSourceAndViewRenderers: existingDetailSourceAndViewRenderers,
            settings: _
        ):
            return SingleStreamViewModel(
                videoViewModels: sources.map {
                    VideoRendererViewModel(
                        streamSource: $0,
                        viewRenderer: existingDetailSourceAndViewRenderers.primaryRenderer(for: $0),
                        isSelectedVideoSource: $0 == selectedVideoSource,
                        isSelectedAudioSource: $0 == selectedAudioSource,
                        showSourceLabel: false,
                        showAudioIndicator: false
                    )
                },
                selectedVideoSource: selectedVideoSource
            )

        default:
            return nil
        }
    }

    // swiftlint:disable function_body_length
    func selectVideoSource(_ source: StreamSource) {
        switch internalState {
        case let .success(
            displayMode: displayMode,
            sources: sources,
            selectedVideoSource: _,
            selectedAudioSource: _,
            sourceAndViewRenderers: sourceAndViewRenderers,
            detailSourceAndViewRenderers: detailSourceAndViewRenderers,
            settings: settings
        ):
            guard let matchingSource = sources.first(where: { $0.id == source.id }) else {
                fatalError("Cannot select source thats not part of the current source list")
            }

            let selectedAudioSource = audioSelection(from: sources, settings: settings, selectedVideoSource: matchingSource)

            let updatedDisplayMode: DisplayMode
            switch displayMode {
            case .list:
                let secondaryVideoSources = sources.filter { $0.id != matchingSource.id }
                let showSourceLabels = settings.showSourceLabels

                let listViewModel = ListViewModel(
                    primaryVideoViewModel: VideoRendererViewModel(
                        streamSource: matchingSource,
                        viewRenderer: sourceAndViewRenderers.primaryRenderer(for: matchingSource),
                        isSelectedVideoSource: true,
                        isSelectedAudioSource: matchingSource.id == selectedAudioSource.id,
                        showSourceLabel: showSourceLabels,
                        showAudioIndicator: matchingSource.id == selectedAudioSource.id
                    ),
                    secondaryVideoViewModels: secondaryVideoSources.map {
                        VideoRendererViewModel(
                            streamSource: $0,
                            viewRenderer: sourceAndViewRenderers.secondaryRenderer(for: $0),
                            isSelectedVideoSource: false,
                            isSelectedAudioSource: $0.id == selectedAudioSource.id,
                            showSourceLabel: showSourceLabels,
                            showAudioIndicator: $0.id == selectedAudioSource.id
                        )
                    }
                )

                updatedDisplayMode = .list(listViewModel)
            case .single:
                let singleStreamViewModel = SingleStreamViewModel(
                    videoViewModels: sources.map {
                        VideoRendererViewModel(
                            streamSource: $0,
                            viewRenderer: sourceAndViewRenderers.primaryRenderer(for: $0),
                            isSelectedVideoSource: $0.id == matchingSource.id,
                            isSelectedAudioSource: $0.id == selectedAudioSource.id,
                            showSourceLabel: false,
                            showAudioIndicator: false
                        )
                    },
                    selectedVideoSource: matchingSource
                )
                updatedDisplayMode = .single(singleStreamViewModel)
            }

            internalState = .success(
                displayMode: updatedDisplayMode,
                sources: sources,
                selectedVideoSource: matchingSource,
                selectedAudioSource: selectedAudioSource,
                sourceAndViewRenderers: sourceAndViewRenderers,
                detailSourceAndViewRenderers: detailSourceAndViewRenderers,
                settings: settings
            )
        default:
            fatalError("Cannot select source when the state is not `.success`")
        }
    }
    // swiftlint:enable function_body_length

    func endStream() async {
        settingsManager.setActiveSetting(for: .global)
        _ = await streamCoordinator.stopSubscribe()
    }

    func playAudio(for source: StreamSource) {
        Task {
            await self.streamCoordinator.playAudio(for: source)
        }
    }

    func stopAudio(for source: StreamSource) {
        Task {
            await self.streamCoordinator.stopAudio(for: source)
        }
    }

    private func startObservers() {
        streamCoordinator.statePublisher
            .combineLatest(settingsManager.settingsPublisher)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state, settings in
                guard let self = self else { return }
                switch state {
                case let .subscribed(sources: sources, numberOfStreamViewers: _):
                    self.updateState(from: sources, settings: settings)
                default:
                    // TODO: Handle other scenarios (including errors)
                    break
                }
            }
            .store(in: &subscriptions)
    }

    // swiftlint:disable cyclomatic_complexity function_body_length
    private func updateState(from sources: [StreamSource], settings: StreamSettings) {
        guard !sources.isEmpty else {
            // TODO: Set proper error messages
            internalState = .error(title: "", subtitle: "")
            return
        }

        updateStreamSettings(from: sources, settings: settings)

        let sortedSources: [StreamSource]
        switch settings.streamSortOrder {
        case .connectionOrder:
            sortedSources = sources
        case .alphaNumeric:
            sortedSources = sources.sorted { $0 < $1 }
        }

        let selectedVideoSource: StreamSource
        let sourceAndViewRenderers: StreamSourceAndViewRenderers
        let detailSourceAndViewRenderers: StreamSourceAndViewRenderers

        switch internalState {
        case .error, .loading:
            selectedVideoSource = sortedSources[0]
            sourceAndViewRenderers = StreamSourceAndViewRenderers()
            detailSourceAndViewRenderers = StreamSourceAndViewRenderers()

        case let .success(
            displayMode: _,
            sources: _,
            selectedVideoSource: currentlySelectedVideoSource,
            selectedAudioSource: _,
            sourceAndViewRenderers: existingSourceAndViewRenderers,
            detailSourceAndViewRenderers: existingDetailSourceAndViewRenderers,
            settings: _
        ):
            selectedVideoSource = currentlySelectedVideoSource
            sourceAndViewRenderers = existingSourceAndViewRenderers
            detailSourceAndViewRenderers = existingDetailSourceAndViewRenderers
        }

        let selectedAudioSource = audioSelection(from: sortedSources, settings: settings, selectedVideoSource: selectedVideoSource)

        let displayMode: DisplayMode
        switch settings.multiviewLayout {
        case .list:
            let secondaryVideoSources = sortedSources.filter { $0.id != selectedVideoSource.id }
            let showSourceLabels = settings.showSourceLabels

            let listViewModel = ListViewModel(
                primaryVideoViewModel: VideoRendererViewModel(
                    streamSource: selectedVideoSource,
                    viewRenderer: sourceAndViewRenderers.primaryRenderer(for: selectedVideoSource),
                    isSelectedVideoSource: true,
                    isSelectedAudioSource: selectedVideoSource.id == selectedAudioSource.id,
                    showSourceLabel: showSourceLabels,
                    showAudioIndicator: selectedVideoSource.id == selectedAudioSource.id
                ),
                secondaryVideoViewModels: secondaryVideoSources.map {
                    VideoRendererViewModel(
                        streamSource: $0,
                        viewRenderer: sourceAndViewRenderers.secondaryRenderer(for: $0),
                        isSelectedVideoSource: false,
                        isSelectedAudioSource: $0.id == selectedAudioSource.id,
                        showSourceLabel: showSourceLabels,
                        showAudioIndicator: $0.id == selectedAudioSource.id
                    )
                }
            )

            displayMode = .list(listViewModel)
        case .single:
            let singleStreamViewModel = SingleStreamViewModel(
                videoViewModels: sortedSources.map {
                    VideoRendererViewModel(
                        streamSource: $0,
                        viewRenderer: sourceAndViewRenderers.primaryRenderer(for: $0),
                        isSelectedVideoSource: $0.id == selectedVideoSource.id,
                        isSelectedAudioSource: $0.id == selectedAudioSource.id,
                        showSourceLabel: false,
                        showAudioIndicator: false
                    )
                },
                selectedVideoSource: selectedVideoSource
            )
            displayMode = .single(singleStreamViewModel)

        default:
            fatalError("Display mode is unhandled")
        }

        self.internalState = .success(
            displayMode: displayMode,
            sources: sortedSources,
            selectedVideoSource: selectedVideoSource,
            selectedAudioSource: selectedAudioSource,
            sourceAndViewRenderers: sourceAndViewRenderers,
            detailSourceAndViewRenderers: detailSourceAndViewRenderers,
            settings: settings
        )
    }

    private func updateStreamSettings(from sources: [StreamSource], settings: StreamSettings) {
        // Only update the settings when the sources change
        let sourceIds = sources.compactMap { source in
            source.sourceId.value
        }
        if sourceIds != settingsManager.settings.audioSources {
            settingsManager.settings.audioSources = sourceIds

            // If source selected in settings is no longer available, update the settings
            if case let .source(sourceId) = settingsManager.settings.audioSelection {
                if !settingsManager.settings.audioSources.contains(sourceId) {
                    settingsManager.settings.audioSelection = .firstSource
                }
            }
        }
    }

    private func audioSelection(from sources: [StreamSource], settings: StreamSettings, selectedVideoSource: StreamSource) -> StreamSource {
        let selectedAudioSource: StreamSource
        switch settings.audioSelection {
        case .firstSource:
            selectedAudioSource = sources[0]
        case .mainSource:
            // If no main source available, use first source as main
            selectedAudioSource = sources.first(where: { $0.sourceId == StreamSource.SourceId.main }) ?? sources[0]
        case .followVideo:
            selectedAudioSource = selectedVideoSource
        case let .source(sourceId: sourceId):
            selectedAudioSource = sources.first(where: { $0.sourceId.value == sourceId }) ?? sources[0]
        }
        return selectedAudioSource
    }
    // swiftlint:enable cyclomatic_complexity function_body_length
}

// swiftlint:enable type_body_length

fileprivate extension StreamViewModel.InternalState {
    var selectedAudioSource: StreamSource? {
        switch self {
        case let .success(
            displayMode: _,
            sources: _,
            selectedVideoSource: _,
            selectedAudioSource: currentlySelectedAudioSource,
            sourceAndViewRenderers: _,
            detailSourceAndViewRenderers: _,
            settings: _
        ):
            return currentlySelectedAudioSource
        default:
            return nil
        }
    }
}

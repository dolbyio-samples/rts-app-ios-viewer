//
//  StreamViewModel.swift
//

import Combine
import DolbyIORTSCore
import Foundation
import MillicastSDK
import SwiftUI
import UIKit

// swiftlint:disable type_body_length
final class StreamViewModel: ObservableObject {

    enum State {
        case loading
        case success(displayMode: DisplayMode)
        case error(ErrorViewModel)

        fileprivate init(_ state: InternalState) {
            switch state {
            case .loading:
                self = .loading
            case let .success(
                displayMode: displayMode,
                sources: _,
                selectedVideoSource: _,
                selectedAudioSource: _,
                settings: _,
                detailSingleStreamViewModel: _
            ):
                self = .success(displayMode: displayMode)
            case let .error(errorViewModel):
                self = .error(errorViewModel)
            }
        }
    }

    fileprivate enum InternalState {
        case loading
        case success(
            displayMode: DisplayMode,
            sources: [StreamSource],
            selectedVideoSource: StreamSource,
            selectedAudioSource: StreamSource?,
            settings: StreamSettings,
            detailSingleStreamViewModel: SingleStreamViewModel?
        )
        case error(ErrorViewModel)
    }

    enum DisplayMode: Equatable {
        static func == (lhs: StreamViewModel.DisplayMode, rhs: StreamViewModel.DisplayMode) -> Bool {
            switch (lhs, rhs) {
            case (.grid, .grid), (.list, .list), (.single, .single):
                return true
            default:
                return false
            }
        }

        case single(SingleStreamViewModel)
        case list(ListViewModel)
        case grid(GridViewModel)
    }

    private let settingsManager: SettingsManager
    private let streamOrchestrator: StreamOrchestrator
    private var subscriptions: [AnyCancellable] = []
    private var timer: Timer?

    let streamDetail: StreamDetail
    let settingsMode: SettingsMode
    let listViewPrimaryVideoQuality: VideoQuality

    private let singleViewRendererProvider: ViewRendererProvider = .init()
    private let gridViewRendererProvider: ViewRendererProvider = .init()
    private let listViewMainRendererProvider: ViewRendererProvider = .init()
    private let listViewThumbnailRendererProvider: ViewRendererProvider = .init()

    @Published private(set) var state: State = .loading
    @Published var isShowingDetailSingleViewScreen: Bool = false {
        didSet {
            guard
                isShowingDetailSingleViewScreen != oldValue,
                let selectedVideoSource = internalState.selectedVideoSource
            else {
                return
            }

            selectVideoSource(selectedVideoSource)
        }
    }

    private var internalState: InternalState = .loading {
        didSet {
            state = State(internalState)

            // Play Audio when the selectedAudioSource changes
            if let newlySelectedAudioSource = internalState.selectedAudioSource,
               newlySelectedAudioSource.id != oldValue.selectedAudioSource?.id {
                playAudio(for: newlySelectedAudioSource)
            }

            // Stop PiP when there is no video streams
            if !internalState.isShowingVideoStreams {
                stopPiP()
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
            settings: _,
            detailSingleStreamViewModel: _
        ):
            return existingSources
        default:
            return []
        }
    }

    init(
        context: StreamingScreen.Context,
        listViewPrimaryVideoQuality: VideoQuality,
        streamOrchestrator: StreamOrchestrator = .shared,
        settingsManager: SettingsManager = .shared
    ) {
        self.streamOrchestrator = streamOrchestrator
        self.settingsManager = settingsManager
        self.streamDetail = context.streamDetail
        self.listViewPrimaryVideoQuality = context.listViewPrimaryVideoQuality
        self.settingsMode = .stream(streamName: streamDetail.streamName, accountID: streamDetail.accountID)

        startObservers()
    }

    var detailSingleStreamViewModel: SingleStreamViewModel? {
        switch internalState {
        case let .success(
            displayMode: _,
            sources: _,
            selectedVideoSource: _,
            selectedAudioSource: _,
            settings: _,
            detailSingleStreamViewModel: viewModel
        ):
            return viewModel

        default:
            return nil
        }
    }

    private func secondaryVideoSources(_ sources: [StreamSource], _ matchingSource: StreamSource) -> [StreamSource] {
        return sources.filter { $0.id != matchingSource.id }
    }

    // swiftlint:disable function_body_length
    func selectVideoSource(_ source: StreamSource) {
        switch internalState {
        case let .success(
            displayMode: displayMode,
            sources: sources,
            selectedVideoSource: _,
            selectedAudioSource: _,
            settings: settings,
            detailSingleStreamViewModel: _
        ):
            guard let matchingSource = sources.first(where: { $0.id == source.id }) else {
                fatalError("Cannot select source thats not part of the current source list")
            }

            let selectedAudioSource = audioSelection(from: sources, settings: settings, selectedVideoSource: matchingSource)

            let updatedDisplayMode: DisplayMode
            switch displayMode {
            case .grid:
                let secondaryVideoSources = secondaryVideoSources(sources, matchingSource)
                let showSourceLabels = settings.showSourceLabels

                let gridViewModel = GridViewModel(
                    primaryVideoViewModel: VideoRendererViewModel(
                        streamSource: matchingSource,
                        isSelectedVideoSource: true,
                        isSelectedAudioSource: matchingSource.id == selectedAudioSource?.id,
                        isPiPView: !isShowingDetailSingleViewScreen,
                        showSourceLabel: showSourceLabels,
                        showAudioIndicator: matchingSource.id == selectedAudioSource?.id,
                        videoQuality: .auto
                    ),
                    secondaryVideoViewModels: secondaryVideoSources.map {
                        VideoRendererViewModel(
                            streamSource: $0,
                            isSelectedVideoSource: false,
                            isSelectedAudioSource: $0.id == selectedAudioSource?.id,
                            isPiPView: false,
                            showSourceLabel: showSourceLabels,
                            showAudioIndicator: $0.id == selectedAudioSource?.id,
                            videoQuality: $0.videoQualityList.contains(.low) ? .low : .auto
                        )
                    },
                    viewRendererProvider: gridViewRendererProvider
                )

                updatedDisplayMode = .grid(gridViewModel)
            case .list:
                let secondaryVideoSources = secondaryVideoSources(sources, matchingSource)
                let showSourceLabels = settings.showSourceLabels
                let primaryVideoQuality = matchingSource.videoQualityList.contains(listViewPrimaryVideoQuality) ? listViewPrimaryVideoQuality : .auto

                let listViewModel = ListViewModel(
                    primaryVideoViewModel: VideoRendererViewModel(
                        streamSource: matchingSource,
                        isSelectedVideoSource: true,
                        isSelectedAudioSource: matchingSource.id == selectedAudioSource?.id,
                        isPiPView: !isShowingDetailSingleViewScreen,
                        showSourceLabel: showSourceLabels,
                        showAudioIndicator: matchingSource.id == selectedAudioSource?.id,
                        videoQuality: primaryVideoQuality
                    ),
                    secondaryVideoViewModels: secondaryVideoSources.map {
                        VideoRendererViewModel(
                            streamSource: $0,
                            isSelectedVideoSource: false,
                            isSelectedAudioSource: $0.id == selectedAudioSource?.id,
                            isPiPView: false,
                            showSourceLabel: showSourceLabels,
                            showAudioIndicator: $0.id == selectedAudioSource?.id,
                            videoQuality: $0.videoQualityList.contains(.low) ? .low : .auto
                        )
                    },
                    mainViewRendererProvider: listViewMainRendererProvider,
                    thumbnailViewRendererProvider: listViewThumbnailRendererProvider
                )

                updatedDisplayMode = .list(listViewModel)
            case .single:
                let singleStreamViewModel = SingleStreamViewModel(
                    videoViewModels: sources.map {
                        VideoRendererViewModel(
                            streamSource: $0,
                            isSelectedVideoSource: $0.id == matchingSource.id,
                            isSelectedAudioSource: $0.id == selectedAudioSource?.id,
                            isPiPView: !isShowingDetailSingleViewScreen && $0.id == matchingSource.id,
                            showSourceLabel: false,
                            showAudioIndicator: false,
                            videoQuality: .auto
                        )
                    },
                    selectedVideoSource: matchingSource,
                    streamDetail: streamDetail,
                    viewRendererProvider: singleViewRendererProvider
                )
                updatedDisplayMode = .single(singleStreamViewModel)
            }

            let detailSingleStreamViewModel = SingleStreamViewModel(
                videoViewModels: sources.map {
                    VideoRendererViewModel(
                        streamSource: $0,
                        isSelectedVideoSource: $0.id == matchingSource.id,
                        isSelectedAudioSource: $0.id == selectedAudioSource?.id,
                        isPiPView: isShowingDetailSingleViewScreen && $0.id == matchingSource.id,
                        showSourceLabel: false,
                        showAudioIndicator: false,
                        videoQuality: .auto
                    )
                },
                selectedVideoSource: matchingSource,
                streamDetail: streamDetail,
                viewRendererProvider: singleViewRendererProvider
            )
            internalState = .success(
                displayMode: updatedDisplayMode,
                sources: sources,
                selectedVideoSource: matchingSource,
                selectedAudioSource: selectedAudioSource,
                settings: settings,
                detailSingleStreamViewModel: detailSingleStreamViewModel
            )
        default:
            fatalError("Cannot select source when the state is not `.success`")
        }
    }
    // swiftlint:enable function_body_length

    func endStream() async throws {
        _ = try await streamOrchestrator.stopConnection()
        subscriptions.removeAll()
    }

    func playAudio(for source: StreamSource) {
        Task { @StreamOrchestrator [weak self] in
            guard let self = self else { return }
            try await self.streamOrchestrator.playAudio(for: source)
        }
    }

    func stopAudio(for source: StreamSource) {
        Task { @StreamOrchestrator [weak self] in
            guard let self = self else { return }
            try await self.streamOrchestrator.stopAudio(for: source)
        }
    }

    private func startObservers() {
        let settingsPublisher = settingsManager.publisher(for: settingsMode)
        Task { @StreamOrchestrator [weak self] in
            guard let self = self else { return }
            await self.streamOrchestrator.statePublisher
                .combineLatest(settingsPublisher)
                .receive(on: DispatchQueue.main)
                .sink { state, settings in
                    switch state {
                    case let .subscribed(sources: sources, numberOfStreamViewers: _):
                        self.updateState(from: sources, settings: settings)
                    case .connected:
                        self.internalState = .loading
                    case let .error(streamError):
                        self.internalState = .error(ErrorViewModel(error: streamError))
                    case .stopped:
                        self.internalState = .error(.streamOffline)
                    case .disconnected:
                        self.internalState = .error(.noInternet)
                    }
                }
                .store(in: &subscriptions)
        }
    }

    // swiftlint:disable function_body_length
    private func updateState(from sources: [StreamSource], settings: StreamSettings) {
        guard !sources.isEmpty else {
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

        switch internalState {
        case .error, .loading:
            selectedVideoSource = sortedSources[0]

        case let .success(
            displayMode: _,
            sources: _,
            selectedVideoSource: currentlySelectedVideoSource,
            selectedAudioSource: _,
            settings: _,
            detailSingleStreamViewModel: _
        ):
            selectedVideoSource = sources.first { $0.id == currentlySelectedVideoSource.id } ?? sortedSources[0]
        }

        let selectedAudioSource = audioSelection(from: sources, settings: settings, selectedVideoSource: selectedVideoSource)

        let displayMode: DisplayMode
        switch settings.multiviewLayout {
        case .list:
            let secondaryVideoSources = sortedSources.filter { $0.id != selectedVideoSource.id }
            let showSourceLabels = settings.showSourceLabels
            let primaryVideoQuality = selectedVideoSource.videoQualityList.contains(listViewPrimaryVideoQuality) ? listViewPrimaryVideoQuality : .auto

            let listViewModel = ListViewModel(
                primaryVideoViewModel: VideoRendererViewModel(
                    streamSource: selectedVideoSource,
                    isSelectedVideoSource: true,
                    isSelectedAudioSource: selectedVideoSource.id == selectedAudioSource?.id,
                    isPiPView: !isShowingDetailSingleViewScreen,
                    showSourceLabel: showSourceLabels,
                    showAudioIndicator: selectedVideoSource.id == selectedAudioSource?.id,
                    videoQuality: primaryVideoQuality
                ),
                secondaryVideoViewModels: secondaryVideoSources.map {
                    VideoRendererViewModel(
                        streamSource: $0,
                        isSelectedVideoSource: false,
                        isSelectedAudioSource: $0.id == selectedAudioSource?.id,
                        isPiPView: false,
                        showSourceLabel: showSourceLabels,
                        showAudioIndicator: $0.id == selectedAudioSource?.id,
                        videoQuality: $0.videoQualityList.contains(.low) ? .low : .auto
                    )
                },
                mainViewRendererProvider: listViewMainRendererProvider,
                thumbnailViewRendererProvider: listViewThumbnailRendererProvider
            )

            displayMode = .list(listViewModel)
        case .grid:
            let secondaryVideoSources = sortedSources.filter { $0.id != selectedVideoSource.id }
            let showSourceLabels = settings.showSourceLabels

            let gridViewModel = GridViewModel(
                primaryVideoViewModel: VideoRendererViewModel(
                    streamSource: selectedVideoSource,
                    isSelectedVideoSource: true,
                    isSelectedAudioSource: selectedVideoSource.id == selectedAudioSource?.id,
                    isPiPView: !isShowingDetailSingleViewScreen,
                    showSourceLabel: showSourceLabels,
                    showAudioIndicator: selectedVideoSource.id == selectedAudioSource?.id,
                    videoQuality: .auto
                ),
                secondaryVideoViewModels: secondaryVideoSources.map {
                    VideoRendererViewModel(
                        streamSource: $0,
                        isSelectedVideoSource: false,
                        isSelectedAudioSource: $0.id == selectedAudioSource?.id,
                        isPiPView: false,
                        showSourceLabel: showSourceLabels,
                        showAudioIndicator: $0.id == selectedAudioSource?.id,
                        videoQuality: $0.videoQualityList.contains(.low) ? .low : .auto
                    )
                },
                viewRendererProvider: gridViewRendererProvider
            )

            displayMode = .grid(gridViewModel)
        case .single:
            let singleStreamViewModel = SingleStreamViewModel(
                videoViewModels: sortedSources.map {
                    VideoRendererViewModel(
                        streamSource: $0,
                        isSelectedVideoSource: $0.id == selectedVideoSource.id,
                        isSelectedAudioSource: $0.id == selectedAudioSource?.id,
                        isPiPView: !isShowingDetailSingleViewScreen && $0.id == selectedVideoSource.id,
                        showSourceLabel: false,
                        showAudioIndicator: false,
                        videoQuality: .auto
                    )
                },
                selectedVideoSource: selectedVideoSource,
                streamDetail: streamDetail,
                viewRendererProvider: singleViewRendererProvider
            )
            displayMode = .single(singleStreamViewModel)
        }

        let detailSingleStreamViewModel = SingleStreamViewModel(
            videoViewModels: sortedSources.map {
                VideoRendererViewModel(
                    streamSource: $0,
                    isSelectedVideoSource: $0.id == selectedVideoSource.id,
                    isSelectedAudioSource: $0.id == selectedAudioSource?.id,
                    isPiPView: isShowingDetailSingleViewScreen && $0.id == selectedVideoSource.id,
                    showSourceLabel: false,
                    showAudioIndicator: false,
                    videoQuality: .auto
                )
            },
            selectedVideoSource: selectedVideoSource,
            streamDetail: streamDetail,
            viewRendererProvider: singleViewRendererProvider
        )
        self.internalState = .success(
            displayMode: displayMode,
            sources: sortedSources,
            selectedVideoSource: selectedVideoSource,
            selectedAudioSource: selectedAudioSource,
            settings: settings,
            detailSingleStreamViewModel: detailSingleStreamViewModel
        )
    }
    // swiftlint:enable function_body_length

    private func updateStreamSettings(from sources: [StreamSource], settings: StreamSettings) {
        // Only update the settings when the sources change, only sources with at least one audio track
        let sourceIds = sources.filter { $0.audioTracksCount > 0 }.compactMap { $0.sourceId.value }
        if sourceIds != settings.audioSources {
            var updatedSettings = settings
            updatedSettings.audioSources = sourceIds

            // If source selected in settings is no longer available, update the settings
            if case let .source(sourceId) = settings.audioSelection, !settings.audioSources.contains(sourceId) {
                updatedSettings.audioSelection = .firstSource
            }

            settingsManager.update(settings: updatedSettings, for: settingsMode)
        }
    }

    private func audioSelection(from sources: [StreamSource], settings: StreamSettings, selectedVideoSource: StreamSource) -> StreamSource? {
        // Get the sources with at least one audio track if none, uses the original sources list
        let sourcesWithAudio = sources.filter { $0.audioTracksCount > 0 }
        if sourcesWithAudio.isEmpty {
            return nil
        }
        let selectedAudioSource: StreamSource?
        switch settings.audioSelection {
        case .firstSource:
            selectedAudioSource = sourcesWithAudio[0]
        case .mainSource:
            // If no main source available, use first source as main
            selectedAudioSource = sourcesWithAudio.first(where: { $0.sourceId == StreamSource.SourceId.main }) ?? sourcesWithAudio[0]
        case .followVideo:
            // Use audio from the video source, if no audio track uses the last one used or just the 1st one
            let fallbackAudioSource = internalState.selectedAudioSource != nil ? internalState.selectedAudioSource : sourcesWithAudio[0]
            selectedAudioSource = selectedVideoSource.audioTracksCount > 0 ? selectedVideoSource : fallbackAudioSource
        case let .source(sourceId: sourceId):
            selectedAudioSource = sourcesWithAudio.first(where: { $0.sourceId == StreamSource.SourceId(id: sourceId) }) ?? sourcesWithAudio[0]
        }
        return selectedAudioSource
    }

    private func stopPiP() {
        PiPManager.shared.stopPiP()
    }
}

fileprivate extension StreamViewModel.InternalState {
    var selectedAudioSource: StreamSource? {
        switch self {
        case let .success(
            displayMode: _,
            sources: _,
            selectedVideoSource: _,
            selectedAudioSource: currentlySelectedAudioSource,
            settings: _,
            detailSingleStreamViewModel: _
        ):
            return currentlySelectedAudioSource
        default:
            return nil
        }
    }

    var selectedVideoSource: StreamSource? {
        switch self {
        case let .success(
            displayMode: _,
            sources: _,
            selectedVideoSource: currentlySelectedVideoSource,
            selectedAudioSource: _,
            settings: _,
            detailSingleStreamViewModel: _
        ):
            return currentlySelectedVideoSource
        default:
            return nil
        }
    }

    var displayMode: StreamViewModel.DisplayMode? {
        switch self {
        case let .success(
            displayMode: currentDisplayMode,
            sources: _,
            selectedVideoSource: _,
            selectedAudioSource: _,
            settings: _,
            detailSingleStreamViewModel: _
        ):
            return currentDisplayMode
        default:
            return nil
        }
    }

    var isShowingVideoStreams: Bool {
        switch self {
        case let .success(
            displayMode: _,
            sources: sources,
            selectedVideoSource: _,
            selectedAudioSource: _,
            settings: _,
            detailSingleStreamViewModel: _
        ):
            return !sources.isEmpty
        default:
            return false
        }
    }
}
// swiftlint:enable type_body_length

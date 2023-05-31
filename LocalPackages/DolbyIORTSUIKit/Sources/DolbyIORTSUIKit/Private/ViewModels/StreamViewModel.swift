//
//  StreamViewModel.swift
//

import Combine
import DolbyIORTSCore
import Foundation

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
            settings: StreamSettings
        )
        case error(title: String, subtitle: String)
    }
    
    enum DisplayMode {
        case single(SingleStreamViewModel)
        case list(ListViewModel)
    }

    private enum Constants {
        static let interactivityTimeOut: CGFloat = 5
    }
    
    private let settingsManager: SettingsManager
    private let streamCoordinator: StreamCoordinator
    private var subscriptions: [AnyCancellable] = []

    @Published private(set) var state: State = .loading
    private var internalState: InternalState = .loading {
        didSet {
            state = State(internalState)
        }
    }

    private var sources: [StreamSource] = []
    
    private func updateState(from sources: [StreamSource], streamDetail: StreamDetail, settings: StreamSettings) {
        guard !sources.isEmpty else {
            // TODO: Set proper error messages
            internalState = .error(title: "", subtitle: "")
            return
        }
        
        // When retreiving sources for the first time
        if self.sources.isEmpty {
            // Update settings manager with the current stream information
            settingsManager.setActiveSetting(for: .stream(streamID: streamDetail.streamId))
        }
        
        let sortedSources: [StreamSource]
        switch settingsManager.settings.streamSortOrder {
        case .connectionOrder:
            sortedSources = sources
        case .alphaNumeric:
            sortedSources = sources.sorted {
                $0.streamId.localizedStandardCompare($1.streamId) == .orderedAscending
            }
        }
        
        let selectedVideoSource: StreamSource
        let sourceAndViewRenderers: StreamSourceAndViewRenderers

        switch internalState {
        case .error, .loading:
            selectedVideoSource = sortedSources[0]
            sourceAndViewRenderers = StreamSourceAndViewRenderers()

        case let .success(
            displayMode: _,
            sources: _,
            selectedVideoSource: currentlySelectedVideoSource,
            selectedAudioSource: _,
            sourceAndViewRenderers: existingSourceAndViewRenderers,
            settings: _
        ):
            selectedVideoSource = currentlySelectedVideoSource
            sourceAndViewRenderers = existingSourceAndViewRenderers
        }
        
        let selectedAudioSource: StreamSource
        switch settings.audioSelection {
        case .firstSource, .mainSource:
            selectedAudioSource = sortedSources[0]
        case .followVideo:
            selectedAudioSource = selectedVideoSource
        case let .source(sourceId: sourceId):
            selectedAudioSource = sortedSources.first { $0.sourceId.value == sourceId } ?? sortedSources[0]
        }
        
        let displayMode: DisplayMode
        switch settings.multiviewLayout {
        case .list:
            let secondaryVideoSources = sortedSources.filter { $0 != selectedVideoSource }

            let listViewModel = ListViewModel(
                primaryVideoViewModel: VideoRendererViewModel(
                    streamSource: selectedVideoSource,
                    viewRenderer: sourceAndViewRenderers.primaryRenderer(for: selectedVideoSource),
                    isSelectedVideoSource: true,
                    isSelectedAudioSource: selectedVideoSource == selectedAudioSource
                ),
                secondaryVideoViewModels: secondaryVideoSources.map {
                    VideoRendererViewModel(
                        streamSource: $0,
                        viewRenderer: sourceAndViewRenderers.primaryRenderer(for: $0),
                        isSelectedVideoSource: false,
                        isSelectedAudioSource: $0 == selectedAudioSource
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
                        isSelectedVideoSource: false,
                        isSelectedAudioSource: $0 == selectedAudioSource
                    )
                }
            )
            displayMode = .single(singleStreamViewModel)
        default:
            fatalError("Display mode is unhandled")
            break
        }
        
        self.internalState = .success(
            displayMode: displayMode,
            sources: sortedSources,
            selectedVideoSource: selectedVideoSource,
            selectedAudioSource: selectedAudioSource,
            sourceAndViewRenderers: sourceAndViewRenderers,
            settings: settings
        )
    }

    init(
        streamCoordinator: StreamCoordinator = .shared,
        settingsManager: SettingsManager = .shared
    ) {
        self.streamCoordinator = streamCoordinator
        self.settingsManager = settingsManager

        startObservers()
    }

    private func startObservers() {
        streamCoordinator.statePublisher
            .combineLatest(settingsManager.settingsPublisher)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state, settings in
                guard let self = self else { return }
                switch state {
                case let .subscribed(sources: sources, numberOfStreamViewers: _, streamDetail: streamDetail):
                    self.updateState(from: sources, streamDetail: streamDetail, settings: settings)
                default:
                    break
                }
            }
            .store(in: &subscriptions)
    }

    func selectVideoSource(_ source: StreamSource) {
        switch internalState {
        case let .success(
            displayMode: displayMode,
            sources: sources,
            selectedVideoSource: selectedVideoSource,
            selectedAudioSource: _,
            sourceAndViewRenderers: sourceAndViewRenderers,
            settings: settings
        ):
            guard self.sources.contains(where: { $0 == source }) else {
                fatalError("Cannot select source thats not part of the current source list")
            }
            
            let selectedAudioSource: StreamSource
            switch settings.audioSelection {
            case .firstSource, .mainSource:
                selectedAudioSource = sources[0]
            case .followVideo:
                selectedAudioSource = selectedVideoSource
            case let .source(sourceId: sourceId):
                selectedAudioSource = sources.first { $0.sourceId.value == sourceId } ?? sources[0]
            }
            
            internalState = .success(
                displayMode: displayMode,
                sources: sources,
                selectedVideoSource: source,
                selectedAudioSource: selectedAudioSource,
                sourceAndViewRenderers: sourceAndViewRenderers,
                settings: settings
            )
        default:
            fatalError("Cannot select source when the state is not `.success`")
            break
        }
    }

    func endStream() async {
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

    // MARK: Manage interactivity on views

    private(set) var interactivityTimer = Timer.publish(every: Constants.interactivityTimeOut, on: .main, in: .common).autoconnect()

    func startInteractivityTimer() {
        interactivityTimer = Timer.publish(every: Constants.interactivityTimeOut, on: .main, in: .common).autoconnect()
    }

    func stopInteractivityTimer() {
        interactivityTimer.upstream.connect().cancel()
    }
}

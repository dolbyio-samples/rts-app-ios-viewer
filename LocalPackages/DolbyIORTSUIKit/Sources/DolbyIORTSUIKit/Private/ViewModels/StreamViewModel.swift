//
//  StreamViewModel.swift
//

import Combine
import DolbyIORTSCore
import Foundation

enum StreamViewMode {
    case single, list
}

final class StreamViewModel: ObservableObject {

    private enum Constants {
        static let interactivityTimeOut: CGFloat = 5
    }

    private let streamCoordinator: StreamCoordinator
    private var subscriptions: [AnyCancellable] = []

    private(set) var selectedVideoStreamSourceId: UUID? {
        didSet {
            updateState()
        }
    }

    private var selectedAudioStreamSourceId: UUID? {
        didSet {
            updateState()
            guard let audioSource = selectedAudioSource else {
                return
            }
            playAudio(for: audioSource)
        }
    }

    private var sources: [StreamSource] = [] {
        didSet {
            if selectedVideoStreamSourceId == nil, let firstSource = sources.first {
                selectedVideoStreamSourceId = firstSource.id
                selectedAudioStreamSourceId = firstSource.id
            }

            updateState()
        }
    }

    private func updateState() {
        isStreamActive = sources.isEmpty == false
        selectedVideoSource = sources.first { $0.id == selectedVideoStreamSourceId }
        selectedAudioSource = sources.first { $0.id == selectedAudioStreamSourceId }
        otherSources = sources.filter { $0.id != selectedVideoStreamSourceId }
        allSources = sources
    }

    @Published private(set) var mode: StreamViewMode = .list
    @Published private(set) var selectedVideoSource: StreamSource?
    @Published private(set) var selectedAudioSource: StreamSource?
    @Published private(set) var otherSources: [StreamSource] = []
    @Published private(set) var allSources: [StreamSource] = []
    @Published private(set) var isStreamActive: Bool = false

    init(streamCoordinator: StreamCoordinator = .shared) {
        self.streamCoordinator = streamCoordinator

        setupStateObservers()
    }

    private func setupStateObservers() {
        streamCoordinator.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                switch state {
                case let .subscribed(sources: sources, numberOfStreamViewers: _, streamDetail: _):
                    self.sources = sources
                default:
                    break
                }
            }
            .store(in: &subscriptions)
    }

    func selectVideoSource(_ source: StreamSource) {
        selectedVideoStreamSourceId = source.id
        selectedAudioStreamSourceId = source.id
    }

    func selectVideoSourceWithId(_ id: UUID) {
        guard let source = allSources.first(where: { $0.id == id }) else {
            return
        }
        selectVideoSource(source)
    }

    func mainViewProvider(for source: StreamSource) -> SourceViewProviding? {
        streamCoordinator.mainSourceViewProvider(for: source)
    }

    func subViewProvider(for source: StreamSource) -> SourceViewProviding? {
        streamCoordinator.subSourceViewProvider(for: source)
    }

    func endStream() async {
        _ = await streamCoordinator.stopSubscribe()
    }

    func playVideo(for source: StreamSource) {
        Task {
            await self.streamCoordinator.playVideo(for: source, quality: .auto)
        }
    }

    func playAudio(for source: StreamSource) {
        Task {
            await self.streamCoordinator.playAudio(for: source)
        }
    }

    func stopVideo(for source: StreamSource) {
        Task {
            await self.streamCoordinator.stopVideo(for: source)
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

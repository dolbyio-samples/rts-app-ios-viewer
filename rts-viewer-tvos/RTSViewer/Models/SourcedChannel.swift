//
//  SourcedChannel.swift
//

import Combine
import Foundation
import os
import RTSCore

class Channel: ObservableObject, Identifiable, Hashable, Equatable {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: Channel.self)
    )

    @Published var currentlyFocusedChannel: Channel? {
        didSet {
            guard let currentlyFocusedChannel else { return }
            isFocusedChannel = currentlyFocusedChannel.id == id
        }
    }

    @Published var isFocusedChannel: Bool = false {
        didSet {
            if isFocusedChannel {
                enableSound()
            } else {
                disableSound()
            }
        }
    }

    @Published private(set) var streamStatistics: StreamStatistics?
    @Published var showStatsView: Bool = false
    @Published var videoQualityList = [VideoQuality]()
    @Published var selectedVideoQuality: VideoQuality = .auto

    let id: UUID
    let streamConfig: StreamConfig
    let subscriptionManager: SubscriptionManager
    let videoTracksManager: VideoTracksManager
    let source: StreamSource
    private var cancellables = [AnyCancellable]()
    private var layersEventsObserver: Task<Void, Never>?

    init(unsourcedChannel: UnsourcedChannel, source: StreamSource) {
        self.id = unsourcedChannel.id
        self.streamConfig = unsourcedChannel.streamConfig
        self.subscriptionManager = unsourcedChannel.subscriptionManager
        self.videoTracksManager = unsourcedChannel.videoTracksManager
        self.source = source

        observeStreamStatistics()
        observeLayerEvents()
        startSelectedQualityObserver()
    }

    func shouldShowStatsView(showStats: Bool) {
        showStatsView = showStats
    }

    func enableVideo(with quality: VideoQuality = .auto) {
        let displayLabel = source.sourceId.displayLabel
        let viewId = "\(ChannelGridView.self).\(displayLabel)"
        Task {
            ChannelGridViewModel.logger.debug("♼ Channel Grid view: Video view appear for \(self.source.sourceId)")
            await self.videoTracksManager.enableTrack(for: self.source, with: quality, on: viewId)
        }
    }

    func disableVideo() {
        let displayLabel = source.sourceId.displayLabel
        let viewId = "\(ChannelGridView.self).\(displayLabel)"
        Task {
            ChannelGridViewModel.logger.debug("♼ Channel Grid view: Video view disappear for \(self.source.sourceId)")
            await self.videoTracksManager.disableTrack(for: self.source, on: viewId)
        }
    }

    func enableSound() {
        Task {
            try? await self.source.audioTrack?.enable()
            Self.logger.debug("♼ Channel \(self.source.sourceId) audio enabled")
        }
    }

    func disableSound() {
        Task {
            try? await self.source.audioTrack?.disable()
            Self.logger.debug("♼ Channel \(self.source.sourceId) audio disabled")
        }
    }

    func updateFocusedChannel(with channel: Channel) {
        currentlyFocusedChannel = channel
    }

    static func == (lhs: Channel, rhs: Channel) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        return hasher.combine(id)
    }
}

private extension Channel {
    func observeStreamStatistics() {
        Task { [weak self] in
            guard let self else { return }
            await subscriptionManager.$streamStatistics
                .sink { statistics in
                    guard let statistics else { return }
                    Task {
                        self.streamStatistics = statistics
                    }
                }
                .store(in: &cancellables)
        }
    }

    func observeLayerEvents() {
        Task { [weak self] in
            guard let self,
                  layersEventsObserver == nil else { return }

            Self.logger.debug("♼ Registering layer events for \(source.sourceId)")
            let layerEventsObservationTask = Task {
                for await layerEvent in self.source.videoTrack.layers() {
                    guard !Task.isCancelled else { return }

                    let videoQualities = layerEvent.layers()
                        .map(VideoQuality.init)
                        .reduce([.auto]) { $0 + [$1] }
                    Self.logger.debug("♼ Received layers \(videoQualities.count)")
                    self.videoQualityList = videoQualities
                }
            }

            layersEventsObserver = layerEventsObservationTask

            _ = await layerEventsObservationTask.value
        }
    }

    func startSelectedQualityObserver() {
        Task { [weak self] in
            guard let self else { return }
            await self.videoTracksManager.selectedVideoQualityPublisher
                .map { $0[self.source.sourceId] ?? .auto }
                .receive(on: DispatchQueue.main)
                .sink { quality in
                    self.selectedVideoQuality = quality
                }
                .store(in: &cancellables)
        }
    }
}

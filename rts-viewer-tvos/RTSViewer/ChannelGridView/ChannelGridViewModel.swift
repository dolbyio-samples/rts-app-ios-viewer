//
//  ChannelGridViewModel.swift
//

import Combine
import Foundation
import MillicastSDK
import os
import SwiftUI

@MainActor
final class ChannelGridViewModel: ObservableObject {
    static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: ChannelGridViewModel.self)
    )

    @Published var channels: [SourcedChannel]
    @Published var currentlyFocusedChannel: SourcedChannel?

    private var cancellables: [AnyCancellable] = []
    private var layersEventsObservationDictionary: [Channel.ID: Task<Void, Never>] = [:]
    private var videoQualityListForChannel: [Channel.ID: [VideoQuality]] = [:]
    private var selectedvideoQualityForChannel: [Channel.ID: VideoQuality] = [:]

    init(channels: [SourcedChannel]) {
        self.channels = channels

        channels.forEach { channel in
            startVideoQualityListObserver(for: channel)
            startSelectedQualityObserver(for: channel)
        }
    }

    func enableVideo(for channel: SourcedChannel, with quality: VideoQuality = .auto) {
        let displayLabel = channel.source.sourceId.displayLabel
        let viewId = "\(ChannelGridView.self).\(displayLabel)"
        Task {
            ChannelGridViewModel.logger.debug("♼ Channel Grid view: Video view appear for \(channel.source.sourceId)")
            await channel.videoTracksManager.enableTrack(for: channel.source, with: quality, on: viewId)
        }
    }

    func disableVideo(for channel: SourcedChannel) {
        let displayLabel = channel.source.sourceId.displayLabel
        let viewId = "\(ChannelGridView.self).\(displayLabel)"
        Task {
            ChannelGridViewModel.logger.debug("♼ Channel Grid view: Video view disappear for \(channel.source.sourceId)")
            await channel.videoTracksManager.disableTrack(for: channel.source, on: viewId)
        }
    }

    func updateFocus(with focusedChannel: SourcedChannel) {
        guard currentlyFocusedChannel != focusedChannel else { return }
        currentlyFocusedChannel = focusedChannel

        let otherChannels = channels.filter { $0.id != focusedChannel.id }
        otherChannels.forEach { channel in
            disableSound(for: channel)
        }
        enableSound(for: focusedChannel)
    }

    func enableSound(for channel: SourcedChannel) {
        Task {
            try? await channel.source.audioTrack?.enable()
            Self.logger.debug("♼ Channel \(channel.source.sourceId) audio enabled")
        }
    }

    func disableSound(for channel: SourcedChannel) {
        Task {
            try? await channel.source.audioTrack?.disable()
            Self.logger.debug("♼ Channel \(channel.source.sourceId) audio disabled")
        }
    }

    func isFocusedChannel(focusedView: ChannelGridView.FocusedView?, currentChannel: SourcedChannel) -> Bool {
        guard let focusedView else { return false }
        var isFocused = false
        if case let .gridView(focusedChannel) = focusedView {
            isFocused = focusedChannel == currentChannel
        }
        return isFocused
    }

    func getVideoQualityList(for channel: SourcedChannel?) -> [VideoQuality] {
        guard let channel,
              let list = videoQualityListForChannel[channel.id] else { return [] }
        print("$$$ list to \(list)")
        return list
    }

    func getSelectedQuality(for channel: SourcedChannel?) -> VideoQuality {
        guard let channel,
              let quality = selectedvideoQualityForChannel[channel.id] else { return .auto }
        return quality
    }
}

private extension ChannelGridViewModel {
    func startVideoQualityListObserver(for channel: SourcedChannel) {
        Task {
            guard layersEventsObservationDictionary[channel.id] == nil else {
                return
            }

            Self.logger.debug("♼ Registering layer events for \(channel.id)")
            let layerEventsObservationTask = Task {
                for await layerEvent in channel.source.videoTrack.layers() {
                    guard !Task.isCancelled else { return }

                    let videoQualities = layerEvent.layers()
                        .map(VideoQuality.init)
                        .reduce([.auto]) { $0 + [$1] }
                    Self.logger.debug("♼ Received layers \(videoQualities.count)")
                    self.videoQualityListForChannel[channel.id] = videoQualities
                }
            }

            layersEventsObservationDictionary[channel.id] = layerEventsObservationTask

            _ = await layerEventsObservationTask.value
        }
    }

    func startSelectedQualityObserver(for channel: SourcedChannel) {
        Task { [weak self] in
            guard let self else { return }
            await channel.videoTracksManager.selectedVideoQualityPublisher
                .map { $0[channel.source.sourceId] ?? .auto }
                .receive(on: DispatchQueue.main)
                .sink { quality in
                    self.selectedvideoQualityForChannel[channel.id] = quality
                    print("$$$ quality is \(quality)")
                }
                .store(in: &cancellables)
        }
    }

    func clearLayerInformation() {
        videoQualityListForChannel.removeAll()
        selectedvideoQualityForChannel.removeAll()
    }

    func reset() {
        Self.logger.debug("🎰 Remove all observations")
        cancellables.removeAll()
        layersEventsObservationDictionary.forEach { id, _ in
            layersEventsObservationDictionary[id]?.cancel()
            layersEventsObservationDictionary[id] = nil
        }

        clearLayerInformation()
//        streamStatistics = nil
    }
}

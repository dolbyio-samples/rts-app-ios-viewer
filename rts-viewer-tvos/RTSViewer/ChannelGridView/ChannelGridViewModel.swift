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

    @Published private(set) var channels: [SourcedChannel]
    @Published private(set) var currentlyFocusedChannel: SourcedChannel?

    private var cancellables: [AnyCancellable] = []

    init(channels: [SourcedChannel]) {
        self.channels = channels
    }

    func enableVideo(for channel: SourcedChannel) {
        let displayLabel = channel.source.sourceId.displayLabel
        let viewId = "\(ChannelGridView.self).\(displayLabel)"
        Task {
            ChannelGridViewModel.logger.debug("♼ Channel Grid view: Video view appear for \(channel.source.sourceId)")
            await channel.videoTracksManager.enableTrack(for: channel.source, with: .auto, on: viewId)
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
            print("Channel \(channel.source.sourceId) audio enabled: \(channel.source.audioTrack?.isActive)")
        }
    }

    func disableSound(for channel: SourcedChannel) {
        Task {
            try? await channel.source.audioTrack?.disable()
            print("Channel \(channel.source.sourceId) audio disabled: \(channel.source.audioTrack?.isActive)")
        }
    }

    func isFocusedChannel(focusedView: ChannelGridView.FocusedView?, currentChannel: SourcedChannel) -> Bool {
        guard let focusedView else { return false}
        var isFocused = false
        if case let .gridView(focusedChannel) = focusedView {
            isFocused = focusedChannel == currentChannel
        }
        return isFocused
    }
}

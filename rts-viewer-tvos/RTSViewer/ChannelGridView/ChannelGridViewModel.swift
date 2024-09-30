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

    func updateFocus(with focusedChannel: SourcedChannel) {
        guard currentlyFocusedChannel != focusedChannel else { return }
        self.currentlyFocusedChannel = focusedChannel

        let otherChannels = channels.filter({$0.id != focusedChannel.id})
        otherChannels.forEach { channel in
            disableSound(for: channel)
        }
        enableSound(for: focusedChannel)

    }

    func enableSound(for channel: SourcedChannel) {
        Task {
            try? await channel.source.audioTrack?.enable()
            print("$$$ Channel \(channel.source.sourceId) audio enabled: \(channel.source.audioTrack?.isActive)")
        }
    }

    func disableSound(for channel: SourcedChannel) {
        print("$$$ disablesound channel: \(channel.id)")
        Task {
            try? await channel.source.audioTrack?.disable()
            print("Channel \(channel.source.sourceId) audio disabled: \(channel.source.audioTrack?.isActive)")
        }
    }
}

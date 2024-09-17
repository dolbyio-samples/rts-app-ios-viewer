//
//  ChannelGridViewModel.swift
//

import Foundation

@MainActor
final class ChannelGridViewModel: ObservableObject {
    @Published var channels: [Channel]

    init(channels: [Channel]) {
        self.channels = channels
    }

    func onAppear(for channel: Channel) {
        channel.enableVideo(with: .auto)
    }

    func onDisappear(for channel: Channel) {
        channel.disableVideo()
        channel.disableSound()
    }

    func updateFocus(with focusedChannel: Channel) {
        channels.forEach { $0.isFocusedChannel = ($0.id == focusedChannel.id) }
    }

    func getCurrentlyFocusedChannel() -> Channel? {
        return channels.first { $0.isFocusedChannel == true }
    }
}

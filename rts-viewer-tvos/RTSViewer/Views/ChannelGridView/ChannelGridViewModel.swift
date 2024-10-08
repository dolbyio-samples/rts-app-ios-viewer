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
        channel.enableVideo()
    }

    func onDisappear(for channel: Channel) {
        channel.disableVideo()
        channel.disableSound()
    }

    func updateFocus(with focusedChannel: Channel) {
        channels.forEach { channel in
            channel.updateFocusedChannel(with: focusedChannel)
        }
    }

    func getCurrentlyFocusedChannel() -> Channel? {
        return channels[0].currentlyFocusedChannel
    }
}

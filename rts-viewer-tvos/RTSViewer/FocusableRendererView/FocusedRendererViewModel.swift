//
//  FocusedRendererViewModel.swift
//

import Foundation
import SwiftUI

@MainActor
class FocusedRendererViewModel: ObservableObject {
    @Published var isFocused: Bool
    @Binding var currentlyFocusedChannel: SourcedChannel?
    let channel: SourcedChannel

    init(channel: SourcedChannel, currentlyFocusedChannel: Binding<SourcedChannel?>, isFocused: Bool) {
        self.isFocused = isFocused
        self.channel = channel
        self._currentlyFocusedChannel = currentlyFocusedChannel

        guard let currentlyFocusedChannel = self.currentlyFocusedChannel else { return }
        self.isFocused = currentlyFocusedChannel.id == channel.id
    }

    func updateFocus(with isFocused: Bool) {
        if isFocused {
            currentlyFocusedChannel = channel
            enableSound(for: channel)
        } else {
            disableSound(for: channel)
        }
    }

    func enableSound(for channel: SourcedChannel) {
        Task {
            try? await channel.source.audioTrack?.enable()
            print("Channel \(channel.source.sourceId) audio enabled: \(channel.source.audioTrack?.isActive)")
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

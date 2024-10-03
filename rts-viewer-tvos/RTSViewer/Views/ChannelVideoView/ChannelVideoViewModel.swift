//
//  ChannelVideoViewModel.swift
//

import Foundation
import os
import SwiftUI

@MainActor
class ChannelVideoViewModel: ObservableObject {
    static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: ChannelVideoViewModel.self)
    )

    @Published var isFocused: Bool {
        didSet {
            print("$$$ isFocused \(isFocused)")
//            if isFocused {
//                print("$$$ enable sound \(isFocused)")
//                enableSound()
//            } else {
//                print("$$$ disable sound \(isFocused)")
//                disableSound()
//            }
        }
    }

    @Binding var focusedChannel: SourcedChannel {
        didSet {
            isFocused = focusedChannel.id == channel.id
            if isFocused {
                print("$$$ enable sound \(isFocused)")
                enableSound()
            } else {
                print("$$$ disable sound \(isFocused)")
                disableSound()
            }
        }
    }

    let channel: SourcedChannel

    init(channel: SourcedChannel, focusedChannel: Binding<SourcedChannel>) {
        print("$$$ init channelvideoviewmodel")
        self.channel = channel
        self._focusedChannel = focusedChannel
        self.isFocused = channel.id == focusedChannel.id
        if isFocused {
            enableSound()
        } else {
            disableSound()
        }
    }

    func enableSound() {
        Task {
            try? await self.channel.source.audioTrack?.enable()
            Self.logger.debug("♼ Channel \(self.channel.source.sourceId) audio enabled")
        }
    }

    func disableSound() {
        Task {
            try? await self.channel.source.audioTrack?.disable()
            Self.logger.debug("♼ Channel \(self.channel.source.sourceId) audio disabled")
        }
    }
}

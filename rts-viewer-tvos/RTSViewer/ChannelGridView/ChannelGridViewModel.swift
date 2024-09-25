//
//  ChannelGridViewModel.swift
//

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

    init(channels: [SourcedChannel]) {
        self.channels = channels
    }

    func enableSound(for channel: SourcedChannel) {
        print("$$$ enablesound channed: \(channel.id)")
        if channel.enableSound {
            Task {
                try? await channel.source.audioTrack?.enable()
                print("$$$ channel \(channel.source.sourceId) audio enabled: \(channel.source.audioTrack?.isActive)")
            }
        }

//        guard let audioTrack = channel.source.audioTrack else { return }
//        if let audioTrack = videoSource.audioTrack, audioTrack.isActive {
//            Self.logger.debug("🎰 Picked source \(videoSource.sourceId) for audio")
//            // Enable new audio track
//            try await audioTrack.enable()
//            await MainActor.run {
//                self.state = .streaming(source: videoSource, playingAudio: true)
//            }
//        }
    }
}

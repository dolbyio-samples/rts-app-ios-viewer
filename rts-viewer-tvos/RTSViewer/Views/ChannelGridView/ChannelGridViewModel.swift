//
//  ChannelGridViewModel.swift
//

import Combine
import Foundation
import MillicastSDK
import os
import RTSCore
import SwiftUI

@MainActor
final class ChannelGridViewModel: ObservableObject {
    static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: ChannelGridViewModel.self)
    )

    @Published var channels: [Channel]

    private var cancellables: [AnyCancellable] = []
    private var layersEventsObservationDictionary: [UnsourcedChannel.ID: Task<Void, Never>] = [:]
    private var videoQualityListForChannel: [UnsourcedChannel.ID: [VideoQuality]] = [:]
    private var selectedvideoQualityForChannel: [UnsourcedChannel.ID: VideoQuality] = [:]

    init(channels: [Channel]) {
        self.channels = channels
    }

    func enableVideo(for channel: Channel, with quality: VideoQuality = .auto) {
        channel.enableVideo(with: quality)
    }

    func disableVideo(for channel: Channel) {
        channel.disableVideo()
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
//
//  SingleStreamViewModel.swift
//

import Combine
import DolbyIORTSCore
import Foundation
import MillicastSDK
import os

@MainActor
final class SingleStreamViewModel: ObservableObject {
    static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: SingleStreamViewModel.self)
    )

    let sources: [StreamSource]
    let selectedVideoSource: StreamSource
    let selectedAudioSource: StreamSource?
    let settingsMode: SettingsMode
    let subscriptionManager: SubscriptionManager
    let videoTracksManager: VideoTracksManager

    init(
        sources: [StreamSource],
        selectedVideoSource: StreamSource,
        selectedAudioSource: StreamSource?,
        settingsMode: SettingsMode,
        subscriptionManager: SubscriptionManager,
        videoTracksManager: VideoTracksManager
    ) {
        self.sources = sources
        self.selectedVideoSource = selectedVideoSource
        self.selectedAudioSource = selectedAudioSource
        self.settingsMode = settingsMode
        self.subscriptionManager = subscriptionManager
        self.videoTracksManager = videoTracksManager
    }

    func streamSource(for id: UUID) -> StreamSource? {
        sources.first { $0.id == id }
    }
}
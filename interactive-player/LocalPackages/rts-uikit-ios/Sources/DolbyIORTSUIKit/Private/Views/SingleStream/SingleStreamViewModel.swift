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
    let sources: [StreamSource]
    let selectedVideoSource: StreamSource
    let selectedAudioSource: StreamSource?
    let settingsMode: SettingsMode
    let subscriptionManager: SubscriptionManager
    let pipRendererRegistry: RendererRegistry
    let videoTracksManager: VideoTracksManager

    init(
        sources: [StreamSource],
        selectedVideoSource: StreamSource,
        selectedAudioSource: StreamSource?,
        settingsMode: SettingsMode,
        pipRendererRegistry: RendererRegistry,
        subscriptionManager: SubscriptionManager,
        videoTracksManager: VideoTracksManager
    ) {
        self.sources = sources
        self.selectedVideoSource = selectedVideoSource
        self.selectedAudioSource = selectedAudioSource
        self.settingsMode = settingsMode
        self.pipRendererRegistry = pipRendererRegistry
        self.subscriptionManager = subscriptionManager
        self.videoTracksManager = videoTracksManager
    }

    func streamSource(for id: UUID) -> StreamSource? {
        sources.first { $0.id == id }
    }
}

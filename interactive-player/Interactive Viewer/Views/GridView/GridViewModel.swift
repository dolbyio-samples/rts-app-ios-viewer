//
//  GridViewModel.swift
//  
//

import RTSCore
import Foundation
import MillicastSDK
import os

final class GridViewModel {
    static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: GridViewModel.self)
    )

    let sources: [StreamSource]
    let selectedVideoSource: StreamSource
    let selectedAudioSource: StreamSource?
    let subscriptionManager: SubscriptionManager
    let showSourceLabels: Bool
    let isShowingDetailView: Bool
    let videoTracksManager: VideoTracksManager

    init(
        sources: [StreamSource],
        selectedVideoSource: StreamSource,
        selectedAudioSource: StreamSource?,
        showSourceLabels: Bool,
        isShowingDetailView: Bool,
        subscriptionManager: SubscriptionManager,
        videoTracksManager: VideoTracksManager
    ) {
        var sortedSources = sources
            .filter { $0.id != selectedVideoSource.id }
        sortedSources.insert(selectedVideoSource, at: 0)

        self.sources = sortedSources
        self.selectedVideoSource = selectedVideoSource
        self.selectedAudioSource = selectedAudioSource
        self.showSourceLabels = showSourceLabels
        self.isShowingDetailView = isShowingDetailView
        self.subscriptionManager = subscriptionManager
        self.videoTracksManager = videoTracksManager
    }
}

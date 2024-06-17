//
//  ListViewModel.swift
//

import DolbyIORTSCore
import Foundation
import MillicastSDK
import os

@MainActor
final class ListViewModel: ObservableObject {
    static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: ListViewModel.self)
    )

    let sources: [StreamSource]
    let selectedVideoSource: StreamSource
    let selectedAudioSource: StreamSource?
    let showSourceLabels: Bool
    let isShowingDetailView: Bool
    let subscriptionManager: SubscriptionManager
    let secondarySources: [StreamSource]
    let mainTilePreferredVideoQuality: VideoQuality
    let videoTracksManager: VideoTracksManager

    init(
        sources: [StreamSource],
        selectedVideoSource: StreamSource,
        selectedAudioSource: StreamSource?,
        showSourceLabels: Bool,
        isShowingDetailView: Bool,
        mainTilePreferredVideoQuality: VideoQuality,
        subscriptionManager: SubscriptionManager,
        videoTracksManager: VideoTracksManager
    ) {
        self.sources = sources
        self.selectedVideoSource = selectedVideoSource
        self.selectedAudioSource = selectedAudioSource
        self.showSourceLabels = showSourceLabels
        self.isShowingDetailView = isShowingDetailView
        self.mainTilePreferredVideoQuality = mainTilePreferredVideoQuality
        self.subscriptionManager = subscriptionManager
        self.secondarySources = sources.filter { $0.id != selectedVideoSource.id }
        self.videoTracksManager = videoTracksManager
    }
}

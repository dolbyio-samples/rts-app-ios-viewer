//
//  GridViewModel.swift
//  
//

import DolbyIORTSCore
import Foundation
import MillicastSDK
import os

@MainActor
final class GridViewModel: ObservableObject {
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
        self.sources = sources
        self.selectedVideoSource = selectedVideoSource
        self.selectedAudioSource = selectedAudioSource
        self.showSourceLabels = showSourceLabels
        self.isShowingDetailView = isShowingDetailView
        self.subscriptionManager = subscriptionManager
        self.videoTracksManager = videoTracksManager
    }
}

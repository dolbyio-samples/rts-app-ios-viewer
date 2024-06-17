//
//  GridViewModel.swift
//  
//

import DolbyIORTSCore
import Foundation
import MillicastSDK
import os

final class GridViewModel {
    let sources: [StreamSource]
    let selectedVideoSource: StreamSource
    let selectedAudioSource: StreamSource?
    let subscriptionManager: SubscriptionManager
    let showSourceLabels: Bool
    let isShowingDetailView: Bool
    let pipRendererRegistry: RendererRegistry
    let videoTracksManager: VideoTracksManager

    init(
        sources: [StreamSource],
        selectedVideoSource: StreamSource,
        selectedAudioSource: StreamSource?,
        showSourceLabels: Bool,
        isShowingDetailView: Bool,
        subscriptionManager: SubscriptionManager,
        pipRendererRegistry: RendererRegistry,
        videoTracksManager: VideoTracksManager
    ) {
        self.sources = sources
        self.selectedVideoSource = selectedVideoSource
        self.selectedAudioSource = selectedAudioSource
        self.showSourceLabels = showSourceLabels
        self.isShowingDetailView = isShowingDetailView
        self.subscriptionManager = subscriptionManager
        self.pipRendererRegistry = pipRendererRegistry
        self.videoTracksManager = videoTracksManager
    }
}

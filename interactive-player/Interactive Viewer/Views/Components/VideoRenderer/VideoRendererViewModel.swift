//
//  VideoRendererViewModel.swift
//

import RTSCore
import Combine
import Foundation
import MillicastSDK
import os

@MainActor
final class VideoRendererViewModel: ObservableObject {
    private enum Constants {
        static let defaultVideoTileSize = CGSize(width: 533, height: 300)
    }

    let isSelectedVideoSource: Bool
    let isSelectedAudioSource: Bool
    let isPiPView: Bool
    let source: StreamSource
    let showSourceLabel: Bool
    let showAudioIndicator: Bool
    let preferredVideoQuality: VideoQuality
    let maxWidth: CGFloat
    let maxHeight: CGFloat
    let videoTracksManager: VideoTracksManager
    @Published private(set) var currentVideoQuality: VideoQuality = .auto

    private let subscriptionManager: SubscriptionManager
    private var subscriptions: [AnyCancellable] = []

    init(
        source: StreamSource,
        isSelectedVideoSource: Bool,
        isSelectedAudioSource: Bool,
        isPiPView: Bool,
        showSourceLabel: Bool,
        showAudioIndicator: Bool,
        maxWidth: CGFloat,
        maxHeight: CGFloat,
        preferredVideoQuality: VideoQuality,
        subscriptionManager: SubscriptionManager,
        videoTracksManager: VideoTracksManager
    ) {
        self.source = source
        self.isSelectedVideoSource = isSelectedVideoSource
        self.isSelectedAudioSource = isSelectedAudioSource
        self.isPiPView = isPiPView
        self.showSourceLabel = showSourceLabel
        self.showAudioIndicator = showAudioIndicator
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
        self.preferredVideoQuality = preferredVideoQuality
        self.subscriptionManager = subscriptionManager
        self.videoTracksManager = videoTracksManager

        observerVideoQualityUpdates()
    }

    var videoSize: CGSize {
        let size = videoTracksManager.rendererRegistry.sampleBufferRenderer(for: source).underlyingRenderer.videoSize
        if size.width > 0, size.height > 0 {
            return size
        } else {
            return Constants.defaultVideoTileSize
        }
    }

    // swiftlint:disable force_cast
    var renderer: MCCMSampleBufferVideoRenderer {
        videoTracksManager.rendererRegistry.sampleBufferRenderer(for: source).underlyingRenderer as! MCCMSampleBufferVideoRenderer
    }

    // swiftlint:enable force_cast

    func tileSize(from videoSize: CGSize) -> CGSize {
        let multiplier = maxWidth / videoSize.width

        let scaledWidth = videoSize.width * multiplier
        let scaledHeight = videoSize.height * multiplier

        return CGSize(width: scaledWidth, height: scaledHeight)
    }

    private func observerVideoQualityUpdates() {
        Task { [weak self] in
            guard let self else { return }
            await self.videoTracksManager.selectedVideoQualityPublisher
                .map({ $0[self.source.sourceId] ?? .auto })
                .receive(on: DispatchQueue.main)
                .sink { quality in
                    self.currentVideoQuality = quality
                }
                .store(in: &subscriptions)
        }
    }
}

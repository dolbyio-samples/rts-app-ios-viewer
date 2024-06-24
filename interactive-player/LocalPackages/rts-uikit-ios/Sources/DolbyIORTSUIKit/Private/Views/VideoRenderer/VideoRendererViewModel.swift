//
//  VideoRendererViewModel.swift
//

import DolbyIORTSCore
import Combine
import Foundation
import MillicastSDK
import os

@MainActor
final class VideoRendererViewModel: ObservableObject {
    static let logger = Logger(
        subsystem: Bundle.module.bundleIdentifier!,
        category: String(describing: VideoRendererViewModel.self)
    )

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
    let rendererRegistry: RendererRegistry
    let maxWidth: CGFloat
    let maxHeight: CGFloat
    let videoTracksManager: VideoTracksManager
    @Published var currentVideoQuality: VideoQuality = .auto

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
        rendererRegistry: RendererRegistry,
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
        self.rendererRegistry = rendererRegistry
        self.videoTracksManager = videoTracksManager

        observerVideoQualityUpdates()
    }

    var videoSize: CGSize {
        let size = rendererRegistry.sampleBufferRenderer(for: source).underlyingRenderer.videoSize
        if size.width > 0, size.height > 0 {
            return size
        } else {
            return Constants.defaultVideoTileSize
        }
    }

    // swiftlint:disable force_cast
    var renderer: MCCMSampleBufferVideoRenderer {
        rendererRegistry.sampleBufferRenderer(for: source).underlyingRenderer as! MCCMSampleBufferVideoRenderer
    }

    // swiftlint:enable force_cast

    func tileSize(from videoSize: CGSize) -> CGSize {
        let multiplier = maxWidth / videoSize.width

        let scaledWidth = videoSize.width * multiplier
        let scaledHeight = videoSize.height * multiplier

        return CGSize(width: scaledWidth, height: scaledHeight)
    }

    func handleViewAppear() {
        VideoRendererViewModel.logger.debug("♼ Tile appear for source \(self.source.sourceId) on renderer \(self.renderer.objectIdentifier.debugDescription)")
        Task {
            await videoTracksManager.enableTrack(
                for: source,
                renderer: renderer,
                preferredVideoQuality: preferredVideoQuality
            )
        }
    }

    func handleViewDisappear() {
        VideoRendererViewModel.logger.debug("♼ Tile disappear for source \(self.source.sourceId) on renderer \(self.renderer.objectIdentifier.debugDescription)")
        Task {
            await videoTracksManager.disableTrack(
                for: source,
                renderer: renderer
            )
        }
    }

    private func observerVideoQualityUpdates() {
        Task { [weak self] in
            guard let self else { return }
            await self.videoTracksManager.videoQualityPublisher
                .map({ $0[self.source.sourceId] ?? .auto })
                .receive(on: DispatchQueue.main)
                .sink { quality in
                    self.currentVideoQuality = quality
                }
                .store(in: &subscriptions)
        }
    }
}

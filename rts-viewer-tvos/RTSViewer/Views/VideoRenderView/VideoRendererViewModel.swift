//
//  VideoRendererViewModel.swift
//

import Combine
import Foundation
import MillicastSDK
import os
import RTSCore

@MainActor
final class VideoRendererViewModel: ObservableObject {
    let source: StreamSource
    let showSourceLabel: Bool
    let showAudioIndicator: Bool
    let maxWidth: CGFloat
    let maxHeight: CGFloat
    let rendererRegistry: RendererRegistry

    private var subscriptions: [AnyCancellable] = []

    private enum Constants {
        static let defaultVideoTileSize = CGSize(width: 533, height: 300)
    }

    init(
        source: StreamSource,
        showSourceLabel: Bool,
        showAudioIndicator: Bool,
        maxWidth: CGFloat,
        maxHeight: CGFloat,
        rendererRegistry: RendererRegistry
    ) {
        self.source = source
        self.showSourceLabel = showSourceLabel
        self.showAudioIndicator = showAudioIndicator
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
        self.rendererRegistry = rendererRegistry
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
        let ratio = calculateAspectRatio(
            screenWidth: maxWidth,
            screenHeight: maxHeight,
            videoWidth: videoSize.width,
            videoHeight: videoSize.height
        )

        let scaledWidth = videoSize.width * ratio
        let scaledHeight = videoSize.height * ratio

        return CGSize(width: scaledWidth, height: scaledHeight)
    }

    private func calculateAspectRatio(
        screenWidth: CGFloat,
        screenHeight: CGFloat,
        videoWidth: CGFloat,
        videoHeight: CGFloat
    ) -> CGFloat {
        guard videoWidth > 0, videoHeight > 0 else {
            return 1.0
        }

        if (screenWidth / videoWidth) < (screenHeight / videoHeight) {
            return screenWidth / videoWidth
        } else {
            return screenHeight / videoHeight
        }
    }
}

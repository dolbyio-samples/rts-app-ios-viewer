//
//  VideoRendererViewModel.swift
//

import DolbyIORTSCore
import Foundation

enum VideoRendererContentMode {
    case aspectFit, aspectFill, scaleToFill
}

final class VideoRendererViewModel {

    private let streamCoordinator: StreamCoordinator
    let isSelectedVideoSource: Bool
    let isSelectedAudioSource: Bool
    let streamSource: StreamSource
    let viewRenderer: StreamSourceViewRenderer

    init(
        streamSource: StreamSource,
        viewRenderer: StreamSourceViewRenderer,
        isSelectedVideoSource: Bool,
        isSelectedAudioSource: Bool,
        streamCoordinator: StreamCoordinator = .shared
    ) {
        self.streamSource = streamSource
        self.viewRenderer = viewRenderer
        self.isSelectedVideoSource = isSelectedVideoSource
        self.isSelectedAudioSource = isSelectedAudioSource
        self.streamCoordinator = streamCoordinator
    }

    func playVideo(for source: StreamSource) {
        Task {
            await self.streamCoordinator.playVideo(for: source, quality: .auto)
        }
    }

    func stopVideo(for source: StreamSource) {
        Task {
            await self.streamCoordinator.stopVideo(for: source)
        }
    }
}

//
//  VideoRendererViewModel.swift
//

import DolbyIORTSCore
import Foundation

enum VideoRendererContentMode {
    case aspectFit, aspectFill, scaleToFill
}

final class VideoRendererViewModel: ObservableObject {

    private let streamCoordinator: StreamCoordinator

    @Published var streamSource: StreamSource

    init(streamSource: StreamSource, streamCoordinator: StreamCoordinator = .shared) {
        self.streamSource = streamSource
        self.streamCoordinator = streamCoordinator
    }

    func getRenderer(for viewIdentifier: String) -> StreamSourceViewRenderer {
        streamCoordinator.getRenderer(for: streamSource, viewIdentifier: viewIdentifier)
    }

    func removeRenderer(for viewIdentifier: String) {
        streamCoordinator.removeRenderer(for: streamSource, viewIdentifier: viewIdentifier)
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

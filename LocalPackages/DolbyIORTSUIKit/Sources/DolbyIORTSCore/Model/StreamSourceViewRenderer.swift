//
//  StreamSourceViewProvider.swift
//

import Foundation
import MillicastSDK
import UIKit

public class StreamSourceViewRenderer: Identifiable {

    enum Constants {
        static let defaultVideoTileSize = CGSize(width: 533, height: 300)
    }

    private let renderer: MCIosVideoRenderer
    private let source: StreamSource
    private var videoTrack: MCVideoTrack

    public let id = UUID()

    public init(_ source: StreamSource) {
        guard let videoTrack = source.videoTrack?.track else {
            fatalError("Cannot request renderer for a source that do not have video track")
        }
        self.renderer = MCIosVideoRenderer()
        self.source = source
        self.videoTrack = videoTrack

        Task {
            await MainActor.run {
                videoTrack.add(renderer)
            }
        }
    }

    private var hasValidDimensions: Bool {
        renderer.getWidth() != 0 && renderer.getHeight() != 0
    }

    public var frameWidth: CGFloat {
        hasValidDimensions ? CGFloat(renderer.getWidth()) : Constants.defaultVideoTileSize.width
    }

    public var frameHeight: CGFloat {
        hasValidDimensions ? CGFloat(renderer.getHeight()) : Constants.defaultVideoTileSize.height
    }

    public var playbackView: UIView {
        renderer.getView()
    }
}

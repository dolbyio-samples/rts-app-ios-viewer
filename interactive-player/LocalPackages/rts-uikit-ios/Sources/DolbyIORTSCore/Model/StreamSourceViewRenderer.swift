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

    public let streamSource: StreamSource
    public let videoTrack: MCVideoTrack
    public let playbackView: MCSampleBufferVideoUIView
    public let pipView: MCSampleBufferVideoUIView
    public let id = UUID()

    private let renderer: MCIosVideoRenderer

    public init(_ streamSource: StreamSource) {
        self.streamSource = streamSource
        let videoTrack = streamSource.videoTrack.track
        self.renderer = MCIosVideoRenderer()
        self.videoTrack = videoTrack

        let playbackView = MCSampleBufferVideoUIView()
        playbackView.scalingMode = .aspectFit
        playbackView.attach(videoTrack: videoTrack, mirrored: false)
        self.playbackView = playbackView

        let pipView = MCSampleBufferVideoUIView()
        pipView.scalingMode = .aspectFit
        pipView.attach(videoTrack: videoTrack, mirrored: false)
        self.pipView = pipView

        Task {
            await MainActor.run {
                videoTrack.add(renderer)
            }
        }
    }

    public var frameWidth: CGFloat {
        hasValidDimensions ? CGFloat(renderer.getWidth()) : Constants.defaultVideoTileSize.width
    }

    public var frameHeight: CGFloat {
        hasValidDimensions ? CGFloat(renderer.getHeight()) : Constants.defaultVideoTileSize.height
    }
}

// MARK: Helper functions

extension StreamSourceViewRenderer {

    private var hasValidDimensions: Bool {
        renderer.getWidth() != 0 && renderer.getHeight() != 0
    }
}

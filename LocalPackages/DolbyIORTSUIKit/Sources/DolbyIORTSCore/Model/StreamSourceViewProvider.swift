//
//  StreamSourceViewProvider.swift
//

import Foundation
import MillicastSDK
import UIKit

public protocol SourceViewProviding {
    var playbackView: UIView { get }
    var frameWidth: CGFloat { get }
    var frameHeight: CGFloat { get }
}

class StreamSourceViewProvider {

    enum Constants {
        static let defaultVideoTileSize = CGSize(width: 533, height: 300)
    }

    var renderer: MCIosVideoRenderer
    var view: UIView?
    init(renderer: MCIosVideoRenderer) {
        self.renderer = renderer
    }

    private var hasValidDimensions: Bool {
        renderer.getWidth() != 0 && renderer.getHeight() != 0
    }
}

extension StreamSourceViewProvider: SourceViewProviding {
    var frameWidth: CGFloat {
        hasValidDimensions ? CGFloat(renderer.getWidth()) : Constants.defaultVideoTileSize.width
    }

    var frameHeight: CGFloat {
        hasValidDimensions ? CGFloat(renderer.getHeight()) : Constants.defaultVideoTileSize.height
    }

    var playbackView: UIView {
        renderer.getView()
    }
}

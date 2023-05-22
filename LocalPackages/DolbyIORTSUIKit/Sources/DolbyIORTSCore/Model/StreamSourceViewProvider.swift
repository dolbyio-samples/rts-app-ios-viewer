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
    var renderer: MCIosVideoRenderer
    var view: UIView?
    init(renderer: MCIosVideoRenderer) {
        self.renderer = renderer
    }
}

extension StreamSourceViewProvider: SourceViewProviding {
    var frameWidth: CGFloat {
        CGFloat(renderer.getWidth() )
    }

    var frameHeight: CGFloat {
        CGFloat(renderer.getHeight() )
    }

    var playbackView: UIView {
        if let view = self.view {
            return view
        } else {
            let view: UIView = renderer.getView()
            self.view = view
            return view
        }
    }
}

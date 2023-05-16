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

struct StreamSourceViewProvider {
    let renderer: MCIosVideoRenderer
}

extension StreamSourceViewProvider: SourceViewProviding {
    var frameWidth: CGFloat {
        CGFloat(renderer.getWidth())
    }

    var frameHeight: CGFloat {
        CGFloat(renderer.getHeight())
    }

    var playbackView: UIView {
        renderer.getView()
    }
}

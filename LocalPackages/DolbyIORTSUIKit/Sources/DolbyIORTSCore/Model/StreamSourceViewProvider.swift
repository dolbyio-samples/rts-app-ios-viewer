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
//    let renderer: MCIosVideoRenderer
    var renderer: MCIosVideoRenderer?
    var view: UIView?
    let track: MCVideoTrack
//    init(renderer: MCIosVideoRenderer) {
//        print("+++++++++++> renderer created: \(renderer)")
//        self.renderer = renderer
//    }
    init(_ track: MCVideoTrack) {
        self.track = track
    }
}

extension StreamSourceViewProvider: SourceViewProviding {
    var frameWidth: CGFloat {
        CGFloat(renderer?.getWidth() ?? 0)
    }

    var frameHeight: CGFloat {
        CGFloat(renderer?.getHeight() ?? 0)
    }

    var playbackView: UIView {
        if let view = self.view {
            return view
        } else {
            let renderer = MCIosVideoRenderer()
            track.add(renderer)
            let view: UIView = renderer.getView()
            self.view = view
            self.renderer = renderer
            print("+++++++++++> view created: \(view)")
            return view
        }
    }
}

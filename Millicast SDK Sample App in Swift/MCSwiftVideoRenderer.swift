//
//  MCSwiftVideoRenderer.swift
//  Millicast SDK Sample App in Swift
//

import AVKit
import Foundation
import MillicastSDK
import SwiftUI

/**
 * Swift version of the MCIosVideoRenderer that can be used in Swift UI.
 * It renders video frames in a UI view and also provides an API to mirror the view.
 */
struct MCSwiftVideoRenderer: UIViewRepresentable {
    var mcMan: MillicastManager?
    var iosRenderer: MCIosVideoRenderer
    var uiView: UIView?

    init(mcMan: MillicastManager) {
        iosRenderer = MCIosVideoRenderer(colorRangeExpansion: false)
        self.mcMan = mcMan
        uiView = iosRenderer.getView()
    }

    func makeUIView(context: Context) -> UIView {
        uiView?.contentMode = .scaleAspectFit
        return uiView!
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    /**
     * Get the MCIosVideoRenderer equivalent of this MCSwiftVideoRenderer.
     */
    public func getIosVideoRenderer() -> MCIosVideoRenderer {
        return iosRenderer
    }

    /**
     * Sets the UIView to be mirrored or not based on the parameter.
     * Runs on main thread.
     *
     * @return True if mirrored state changed, false otherwise.
     */
    public func setMirror(_ mirror: Bool) -> Bool {
        let logTag = "[Video][Render][er][Mirror]:\(mirror). "
        if let view = uiView {
            var task = { [self] in
                var log = "Set current mirrored state to "
                if mirror {
                    view.transform = CGAffineTransformMakeScale(-1, 1)
                    log += "true."
                } else {
                    view.transform = .identity
                    log += "false."
                }
                print(logTag + log + " isMirrored:\(mirror).")
            }
            mcMan?.runOnMain(logTag: logTag, log: "Mirror view", task)
            return true
        }
        return false
    }
}

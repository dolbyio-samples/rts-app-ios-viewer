//
//  VideoRenderer.swift
//  

import AVKit
import Foundation
import MillicastSDK
import SwiftUI

struct VideoRendererView: UIViewRepresentable {
    private let uiView: UIView

    init(uiView: UIView) {
        self.uiView = uiView
    }

    func makeUIView(context: Context) -> UIView {
        uiView.contentMode = .scaleAspectFit
        return uiView
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

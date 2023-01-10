//
//  VideoRenderer.swift
//  RTSViewer

import AVKit
import Foundation
import MillicastSDK
import SwiftUI

public struct VideoRendererView: UIViewRepresentable {
    private let uiView: UIView
    
    public init(uiView: UIView) {
        self.uiView = uiView
    }
    
    public func makeUIView(context: Context) -> UIView {
        uiView.contentMode = .scaleAspectFit
        return uiView
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {}
}

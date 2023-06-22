//
//  VideoView.swift
//

import DolbyIOUIKit
import Foundation
import SwiftUI
import RTSComponentKit

struct VideoView: View {
    private var streamingView: UIView

    private var updateScreenSize: (Float, Float) -> Void

    private var width: CGFloat
    private var height: CGFloat

    private var highlighted: Bool
    private var onAction: () -> Void

    init(streamingView: UIView, width: CGFloat, height: CGFloat, updateScreenSize: @escaping (Float, Float) -> Void, highlighted: Bool = false, onAction: @escaping () -> Void = {}) {
        self.streamingView = streamingView
        self.updateScreenSize = updateScreenSize
        self.width = width
        self.height = height

        self.highlighted = highlighted
        self.onAction = onAction
    }

    var body: some View {
        GeometryReader { geometry in
            VideoRendererView(uiView: streamingView)
                .onRotate { orientation in
                    if orientation.isPortrait || orientation.isLandscape {
                        let currentScreenSize = currentScreenSize(orientation: orientation, geometry: geometry)
                        updateScreenSize(currentScreenSize.0, currentScreenSize.1)
                    }
                }
                .frame(width: width, height: height)
                .overlay(highlighted ? Rectangle()
                    .stroke(
                        Color(uiColor: UIColor.white),
                        lineWidth: Layout.border3x
                    ) : nil)
                .frame(width: geometry.size.width, height: geometry.size.height)
        }.onTapGesture {
            onAction()
        }
    }

    private func currentScreenSize(orientation: UIDeviceOrientation, geometry: GeometryProxy) -> (Float, Float) {
        var screenWidth, screenHeight: CGFloat
        if (orientation.isPortrait && geometry.size.width < geometry.size.height)
            || (orientation.isLandscape && geometry.size.width > geometry.size.height) {
            screenWidth = geometry.size.width
            screenHeight = geometry.size.height
        } else {
            screenWidth = geometry.size.height
            screenHeight = geometry.size.width
        }
        return (Float(screenWidth), Float(screenHeight))
    }
}

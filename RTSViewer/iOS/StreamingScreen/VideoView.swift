//
//  VideoView.swift
//

import DolbyIOUIKit
import Foundation
import SwiftUI
import RTSComponentKit

struct VideoView: View {
    @ObservedObject private var viewModel: DisplayStreamViewModel

    init(viewModel: DisplayStreamViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        GeometryReader { geometry in
            VideoRendererView(uiView: viewModel.streamingView)
                .onRotate { orientation in
                    let currentScreenSize = currentScreenSize(orientation: orientation, geometry: geometry)
                    viewModel.updateScreenSize(width: currentScreenSize.0, height: currentScreenSize.1)
                }
                .frame(width: viewModel.width, height: viewModel.height)
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    private func currentScreenSize(orientation: UIDeviceOrientation, geometry: GeometryProxy) -> (Float, Float) {
        var screenWidth, screenHeight: CGFloat
        if (orientation.isPortrait && geometry.size.width < geometry.size.height)
            || (!orientation.isPortrait && geometry.size.width > geometry.size.height) {
            screenWidth = geometry.size.width
            screenHeight = geometry.size.height
        } else {
            screenWidth = geometry.size.height
            screenHeight = geometry.size.width
        }
        return (Float(screenWidth), Float(screenHeight))
    }
}

private struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
            .onAppear {
                action(UIDevice.current.orientation)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                action(UIDevice.current.orientation)
            }
    }
}

private extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}

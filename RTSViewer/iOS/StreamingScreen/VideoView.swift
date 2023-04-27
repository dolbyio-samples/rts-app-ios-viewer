//
//  VideoView.swift
//

import DolbyIOUIKit
import Foundation
import SwiftUI
import RTSComponentKit

struct VideoView: View {
    @ObservedObject private var viewModel: DisplayStreamViewModel

    private var showFullScreen: Bool
    private var highlighted: Bool
    private var onAction: () -> Void

    init(viewModel: DisplayStreamViewModel, showFullScreen: Bool, highlighted: Bool = false, onAction: @escaping () -> Void = {}) {
        self.viewModel = viewModel
        self.showFullScreen = showFullScreen
        self.highlighted = highlighted
        self.onAction = onAction
    }

    var body: some View {
        GeometryReader { geometry in
            VideoRendererView(uiView: viewModel.streamingView)
                .onRotate { orientation in
                    if orientation.isPortrait || orientation.isLandscape {
                        let currentScreenSize = currentScreenSize(orientation: orientation, geometry: geometry)
                        viewModel.updateScreenSize(width: currentScreenSize.0, height: currentScreenSize.1)
                    }
                }
                .frame(width: viewModel.width, height: viewModel.height)
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

private struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard let interfaceOrientation = UIApplication.shared.connectedScenes.map({ $0 as? UIWindowScene }).compactMap({ $0 }).first?.windows.first?.windowScene?.interfaceOrientation else {
                    action(UIDevice.current.orientation)
                    return
                }
                action(UIDeviceOrientation(rawValue: (interfaceOrientation).rawValue)!)
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

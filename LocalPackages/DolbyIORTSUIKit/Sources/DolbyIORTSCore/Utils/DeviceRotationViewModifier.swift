//
//  DeviceRotationViewModifier.swift
//

import UIKit
import SwiftUI

public struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    public func body(content: Content) -> some View {
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

public extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}

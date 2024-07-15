//
//  DeviceRotationViewModifier.swift
//

import UIKit
import SwiftUI

#if os(iOS)
public struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    public func body(content: Content) -> some View {
        content
            .onAppear {
                handleOrientation()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                handleOrientation()
            }
    }

    func handleOrientation() {
        guard let interfaceOrientation = UIApplication.shared.connectedScenes.map({ $0 as? UIWindowScene }).compactMap({ $0 }).first?.windows.first?.windowScene?.interfaceOrientation else {
            action(UIDevice.current.orientation)
            return
        }
        guard let orientationValue = UIDeviceOrientation(rawValue: (interfaceOrientation).rawValue) else { return }
        action(orientationValue)
    }
}

public extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}
#endif

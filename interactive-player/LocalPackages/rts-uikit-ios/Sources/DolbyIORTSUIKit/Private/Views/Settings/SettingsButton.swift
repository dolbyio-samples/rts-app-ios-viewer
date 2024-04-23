//
//  SettingsButton.swift
//

import DolbyIOUIKit
import SwiftUI

public struct SettingsButton: View {

    private let onAction: () -> Void

    public init(onAction: @escaping (() -> Void) = {}) {
        self.onAction = onAction
    }

    public var body: some View {
        IconButton(iconAsset: .settings, action: {
            onAction()
        })
    }
}

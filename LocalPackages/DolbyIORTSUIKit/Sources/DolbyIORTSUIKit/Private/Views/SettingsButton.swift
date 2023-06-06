//
//  SettingsButton.swift
//

import DolbyIOUIKit
import SwiftUI

struct SettingsButton: View {

    private let onAction: () -> Void

    init(onAction: @escaping (() -> Void) = {}) {
        self.onAction = onAction
    }

    var body: some View {
        IconButton(name: .settings, action: {
            onAction()
        })
        .scaleEffect(0.5, anchor: .trailing)
    }
}

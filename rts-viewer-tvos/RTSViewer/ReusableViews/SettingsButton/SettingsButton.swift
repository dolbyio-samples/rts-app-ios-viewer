//
//  SettingsButton.swift
//

import SwiftUI
import DolbyIOUIKit

struct SettingsButton: View {
    let action: () -> Void
    var body: some View {
        IconButton(
            text: "stream.settings.button",
            name: .settings,
            action: action
        )
    }
}

#Preview {
    SettingsButton(action: {})
}

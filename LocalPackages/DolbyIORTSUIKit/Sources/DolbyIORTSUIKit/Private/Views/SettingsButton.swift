//
//  SettingsButton.swift
//

import DolbyIOUIKit
import DolbyIORTSCore
import SwiftUI

struct SettingsButton: View {

    @Binding private var isShowingSettingsScreen: Bool

    init(isShowingSettingsScreen: Binding<Bool>) {
        _isShowingSettingsScreen = isShowingSettingsScreen
    }

    var body: some View {
        IconButton(name: .settings, action: {
            _isShowingSettingsScreen.wrappedValue = true
        })
        .scaleEffect(0.5, anchor: .trailing)
    }
}

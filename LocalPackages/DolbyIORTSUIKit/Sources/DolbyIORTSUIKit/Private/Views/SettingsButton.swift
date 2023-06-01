//
//  SettingsButton.swift
//

import DolbyIOUIKit
import DolbyIORTSCore
import SwiftUI

struct SettingsButton: View {

    @Binding private var isShowingSettingsScreen: Bool

    init(streamId: String, isShowingSettingsScreen: Binding<Bool>, settingsManager: SettingsManager = .shared) {
        _isShowingSettingsScreen = isShowingSettingsScreen
        settingsManager.setActiveSetting(for: .stream(streamID: streamId))
    }

    var body: some View {
        IconButton(name: .settings, action: {
            _isShowingSettingsScreen.wrappedValue = true
        })
        .scaleEffect(0.5, anchor: .trailing)
    }
}

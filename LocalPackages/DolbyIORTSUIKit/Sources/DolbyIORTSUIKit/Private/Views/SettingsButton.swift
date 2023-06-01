//
//  SettingsButton.swift
//

import DolbyIORTSCore
import DolbyIOUIKit
import SwiftUI

struct SettingsButton: View {

    let onClick: (() -> Void)

    init(onClick: @escaping (() -> Void) = {}) {
        self.onClick = onClick
    }

    var body: some View {
        IconButton(name: .settings, action: {
            onClick()
        })
        .scaleEffect(0.5, anchor: .trailing)
    }
}

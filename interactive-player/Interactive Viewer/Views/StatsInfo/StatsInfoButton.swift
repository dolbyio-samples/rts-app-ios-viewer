//
//  StatsInfoButton.swift
//

import DolbyIORTSCore
import DolbyIOUIKit
import SwiftUI

struct StatsInfoButton: View {

    private let onAction: () -> Void

    init(onAction: @escaping (() -> Void)) {
        self.onAction = onAction
    }

    var body: some View {
        IconButton(
            iconAsset: .info
        ) {
            onAction()
        }
    }
}

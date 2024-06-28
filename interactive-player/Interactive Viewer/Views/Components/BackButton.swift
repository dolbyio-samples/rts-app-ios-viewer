//
//  BackButton.swift
//

import DolbyIOUIKit
import SwiftUI

struct BackButton: View {

    private let onBack: () -> Void
    init(backAction: @escaping () -> Void) {
        onBack = backAction
    }

    var body: some View {
        IconButton(
            iconAsset: .chevronLeft
        ) {
            onBack()
        }
    }
}

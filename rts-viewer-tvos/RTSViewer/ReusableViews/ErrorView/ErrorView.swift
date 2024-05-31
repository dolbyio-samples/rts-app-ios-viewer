//
//  ErrorView.swift
//

import DolbyIOUIKit
import Foundation
import SwiftUI

struct ErrorView: View {
    private let title: String
    private let subtitle: String?
    private let theme = ThemeManager.shared.theme

    init(title: String, subtitle: String?) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack {
            Text(verbatim: title)
                .font(
                    theme[.avenirNextDemiBold(
                        size: FontSize.title3,
                        style: .title3
                    )]
                )

            if let subtitle {
                Text(verbatim: subtitle)
                    .font(
                        theme[.avenirNextRegular(
                            size: FontSize.caption2,
                            style: .caption2
                        )]
                    )
            }
        }
    }
}

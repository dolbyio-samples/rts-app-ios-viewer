//
//  RecentStreamButton.swift
//

import DolbyIOUIKit
import SwiftUI

struct RecentStreamButton: View {
    let streamName: String
    let accountID: String
    let action: () -> Void

    private let theme = ThemeManager.shared.theme
    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: action) {
            HStack {
                Spacer()
                SwiftUI.Text("recent-streams.format.label \(streamName) \(accountID)")
                    .font(
                        theme[
                            .avenirNextDemiBold(
                                size: FontSize.caption1,
                                style: .caption
                            )
                        ]
                    )
                    .foregroundColor(
                        Color(
                            uiColor: isFocused ? UIColor.Neutral.neutral500 : UIColor.Typography.Dark.primary
                        )
                    )
                Spacer()
            }
        }
        .focused($isFocused)
#if os(tvOS)
        .buttonStyle(
            ClearButtonStyle(
                isFocused: isFocused,
                focusedBackgroundColor: .clear
            )
        )
#else
        .buttonStyle(.plain)
#endif
        .frame(maxWidth: .infinity, minHeight: 60)
        .background(
            Color(
                uiColor: isFocused ? UIColor.Neutral.neutral50 : UIColor.Background.black
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cornerRadius6x)
                .stroke(
                    Color(uiColor: UIColor.Neutral.neutral300),
                    lineWidth: Layout.border2x
                )
        )
        .mask(RoundedRectangle(cornerRadius: Layout.cornerRadius6x))
    }
}

#if DEBUG
struct RecentStreamButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            RecentStreamButton(streamName: "ABCDE", accountID: "12345", action: {})
        }
    }
}
#endif

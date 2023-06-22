//
//  RecentStreamCell.swift
//

import DolbyIOUIKit
import SwiftUI

struct RecentStreamCell: View {
    private let streamName: String
    private let accountID: String

    private let theme = ThemeManager.shared.theme
    private let action: () -> Void

    init(
        streamName: String,
        accountID: String,
        action: @escaping () -> Void
    ) {
        self.streamName = streamName
        self.accountID = accountID
        self.action = action
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                DolbyIOUIKit.Text(
                    text: "recent-streams.stream-name.format.label \(streamName)",
                    font: .custom("AvenirNext-Regular", size: FontSize.callout, relativeTo: .callout)
                )

                HStack {
                    DolbyIOUIKit.Text(
                        text: "recent-streams.account-id.title.label",
                        font: .custom("AvenirNext-Regular", size: FontSize.subhead, relativeTo: .subheadline)
                    )

                    DolbyIOUIKit.Text(
                        text: "recent-streams.account-id.format.label \(accountID)",
                        mode: .secondary,
                        font: .custom("AvenirNext-Regular", size: FontSize.subhead, relativeTo: .subheadline)
                    )

                }
            }
            Spacer()
            IconButton(iconAsset: .playOutlined, tintColor: .white, action: action)
        }
        .padding(.leading, Layout.spacing3x)
        .padding(.trailing, Layout.spacing1x)
        .padding([.top, .bottom], Layout.spacing2x)
        .background(Color(uiColor: theme.neutral700))
        .mask(RoundedRectangle(cornerRadius: Layout.cornerRadius6x))
    }
}

struct RecentStreamCell_Previews: PreviewProvider {
    static var previews: some View {
        RecentStreamCell(streamName: "ABCDE", accountID: "12345", action: {})
    }
}

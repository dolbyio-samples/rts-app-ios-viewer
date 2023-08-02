//
//  RecentStreamCell.swift
//

import DolbyIOUIKit
import SwiftUI

struct RecentStreamCell: View {
    private let streamName: String
    private let accountID: String
    private let isDev: Bool
    private let forcePlayoutDelay: Bool
    private let disableAudio: Bool
    private let saveLogs: Bool
    private let jitterBufferDelay: Int

    @ObservedObject private var themeManager = ThemeManager.shared
    private let action: () -> Void

    init(
        streamName: String,
        accountID: String,
        dev: Bool,
        forcePlayoutDelay: Bool,
        disableAudio: Bool,
        saveLogs: Bool,
        jitterBufferDelay: Int,
        action: @escaping () -> Void
    ) {
        self.streamName = streamName
        self.accountID = accountID
        self.action = action
        self.isDev = dev
        self.forcePlayoutDelay = forcePlayoutDelay
        self.disableAudio = disableAudio
        self.saveLogs = saveLogs
        self.jitterBufferDelay = jitterBufferDelay
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                DolbyIOUIKit.Text(
                    "recent-streams.stream-name.format.label \(streamName)",
                    font: .custom("AvenirNext-Regular", size: FontSize.callout, relativeTo: .callout)
                )

                HStack {
                    DolbyIOUIKit.Text(
                        "recent-streams.account-id.title.label",
                        font: .custom("AvenirNext-Regular", size: FontSize.subhead, relativeTo: .subheadline)
                    )

                    DolbyIOUIKit.Text(
                        "recent-streams.account-id.format.label \(accountID)",
                        style: .labelMedium,
                        font: .custom("AvenirNext-Regular", size: FontSize.subhead, relativeTo: .subheadline)
                    )
                }
                DolbyIOUIKit.Text(
                    "dev: \(String(isDev))",
                    style: .labelMedium,
                    font: .custom("AvenirNext-Regular", size: FontSize.subhead, relativeTo: .subheadline)
                )

                DolbyIOUIKit.Text(
                    "noPlayoutDelay: \(String(forcePlayoutDelay))",
                    style: .labelMedium,
                    font: .custom("AvenirNext-Regular", size: FontSize.subhead, relativeTo: .subheadline)
                )

                DolbyIOUIKit.Text(
                    "disableAudio: \(String(disableAudio))",
                    style: .labelMedium,
                    font: .custom("AvenirNext-Regular", size: FontSize.subhead, relativeTo: .subheadline)
                )

                DolbyIOUIKit.Text(
                    "saveLogs: \(String(saveLogs))",
                    style: .labelMedium,
                    font: .custom("AvenirNext-Regular", size: FontSize.subhead, relativeTo: .subheadline)
                )

                DolbyIOUIKit.Text(
                    "jitter buffer delay: \(String(jitterBufferDelay))",
                    style: .labelMedium,
                    font: .custom("AvenirNext-Regular", size: FontSize.subhead, relativeTo: .subheadline)
                )
            }
            Spacer()
            IconButton(iconAsset: .playOutlined, tintColor: .white, action: action)
        }
        .padding(.leading, Layout.spacing3x)
        .padding(.trailing, Layout.spacing1x)
        .padding([.top, .bottom], Layout.spacing2x)
        .background(Color(uiColor: themeManager.theme.neutral700))
        .mask(RoundedRectangle(cornerRadius: Layout.cornerRadius6x))
    }
}

struct RecentStreamCell_Previews: PreviewProvider {
    static var previews: some View {
        RecentStreamCell(
            streamName: "ABCDE",
            accountID: "12345",
            dev: false,
            forcePlayoutDelay: false,
            disableAudio: false,
            saveLogs: false,
            jitterBufferDelay: 0,
            action: {})
    }
}

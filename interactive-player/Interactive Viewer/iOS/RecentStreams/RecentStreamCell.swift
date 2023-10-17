//
//  RecentStreamCell.swift
//

import DolbyIOUIKit
import DolbyIORTSCore
import DolbyIORTSUIKit
import SwiftUI

struct RecentStreamCell: View {
    private typealias StreamDetailKeyValuePair = (key: String, value: String)

    private let streamDetail: SavedStreamDetail

    @AppConfiguration(\.showDebugFeatures) var showDebugFeatures
    @ObservedObject private var themeManager = ThemeManager.shared

    private var detailFields: [StreamDetailKeyValuePair] {
        var fields: [StreamDetailKeyValuePair] = [(String(localized: "recent-streams.account-id.title.label"), streamDetail.accountID)]
        if showDebugFeatures {
            fields.append(
                contentsOf: [
                    (String(localized: "recent-streams.use-dev-server.label"), String(streamDetail.useDevelopmentServer)),
                    (String(localized: "recent-streams.video-jitter-buffer.label"), String(streamDetail.videoJitterMinimumDelayInMs)),
                    (String(localized: "recent-streams.no-playout-delay.label"), String(streamDetail.noPlayoutDelay)),
                    (String(localized: "recent-streams.disable-audio.label"), String(streamDetail.disableAudio)),
                    (String(localized: "recent-streams.primary-video-quality.label"), streamDetail.primaryVideoQuality.description)
                ]
            )
        }
        return fields
    }

    private let action: () -> Void

    init(
        streamDetail: SavedStreamDetail,
        action: @escaping () -> Void
    ) {
        self.streamDetail = streamDetail
        self.action = action
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                DolbyIOUIKit.Text(
                    verbatim: streamDetail.streamName,
                    font: .custom("AvenirNext-Regular", size: FontSize.callout, relativeTo: .callout)
                )

                ForEach(detailFields, id: \.key) { field in
                    HStack {
                        DolbyIOUIKit.Text(
                            verbatim: field.key,
                            font: .streamDetailFont
                        )

                        DolbyIOUIKit.Text(
                            verbatim: field.value,
                            font: .streamDetailFont
                        )
                    }
                }
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

private extension Font {
    static let streamDetailFont: Font = .custom("AvenirNext-Regular", size: FontSize.subhead, relativeTo: .subheadline)

}

struct RecentStreamCell_Previews: PreviewProvider {
    static var previews: some View {
        RecentStreamCell(
            streamDetail: SavedStreamDetail(
                accountID: "12345",
                streamName: "ABCDE",
                useDevelopmentServer: true,
                videoJitterMinimumDelayInMs: 20,
                noPlayoutDelay: true,
                disableAudio: true,
                primaryVideoQuality: .auto
            ),
            action: {}
        )
    }
}

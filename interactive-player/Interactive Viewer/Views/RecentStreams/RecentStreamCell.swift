//
//  RecentStreamCell.swift
//

import DolbyIOUIKit
import RTSCore
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
                    (String(localized: "recent-streams.server-url.label"), String(streamDetail.subscribeAPI)),
                    (String(localized: "recent-streams.video-jitter-buffer.label"), String(streamDetail.videoJitterMinimumDelayInMs)),
                    (String(localized: "recent-streams.min-playout-delay.label"), String(streamDetail.minPlayoutDelay)),
                    (String(localized: "recent-streams.max-playout-delay.label"), String(streamDetail.maxPlayoutDelay))
                ]
            )
            fields.append(
                contentsOf: [
                    (String(localized: "recent-streams.disable-audio.label"), String(streamDetail.disableAudio)),
                    (String(localized: "recent-streams.primary-video-quality.label"), streamDetail.primaryVideoQuality.displayText),
                    (String(localized: "recent-streams.max-bitrate.label"), String(streamDetail.maxBitrate)),
                    (String(localized: "recent-streams.save-logs.label"), String(streamDetail.saveLogs))
                ]
            )
        }
        return fields
    }

    private let action: () -> Void

    init(streamDetail: SavedStreamDetail, action: @escaping () -> Void) {
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
                .accessibilityIdentifier("\(streamDetail.streamName).PlayIconButton")
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
                subscribeAPI: "https://director.com",
                videoJitterMinimumDelayInMs: 20,
                minPlayoutDelay: 0,
                maxPlayoutDelay: 0,
                disableAudio: true,
                primaryVideoQuality: .auto,
                maxBitrate: 0,
                forceSmooth: true,
                monitorDuration: SubscriptionConfiguration.Constants.bweMonitorDurationUs,
                rateChangePercentage: SubscriptionConfiguration.Constants.bweRateChangePercentage,
                upwardsLayerWaitTimeMs: SubscriptionConfiguration.Constants.upwardsLayerWaitTimeMs,
                saveLogs: false
            ),
            action: {}
        )
    }
}

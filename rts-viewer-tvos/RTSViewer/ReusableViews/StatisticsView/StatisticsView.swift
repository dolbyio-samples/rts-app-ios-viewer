//
//  StatisticsView.swift
//

import DolbyIOUIKit
import Foundation
import MillicastSDK
import RTSCore
import SwiftUI

struct StatisticsView: View {
    private let viewModel: StatisticsViewModel
    private let fontAssetTable = FontAsset.avenirNextRegular(size: FontSize.caption2, style: .caption2)
    private let fontTable = Font.avenirNextRegular(withStyle: .caption2, size: FontSize.caption2)
    private let fontAssetCaption = FontAsset.avenirNextDemiBold(size: FontSize.caption1, style: .caption)
    private let fontAssetTitle: FontAsset
    private let theme = ThemeManager.shared.theme
    private let isMultiChannel: Bool

    init(
        source: StreamSource,
        streamStatistics: StreamStatistics,
        layers: [MCRTSRemoteTrackLayer],
        projectedTimeStamp: Double?,
        isMultiChannel: Bool = false
    ) {
        viewModel = StatisticsViewModel(
            source: source,
            streamStatistics: streamStatistics,
            layers: layers,
            projectedTimeStamp: projectedTimeStamp,
            isMultiChannel: isMultiChannel
        )
        fontAssetTitle = isMultiChannel ? FontAsset.avenirNextBold(size: FontSize.caption1, style: .caption) : FontAsset.avenirNextBold(size: FontSize.title3, style: .title3)
        self.isMultiChannel = isMultiChannel
    }

    var body: some View {
        VStack {
            Text(text: "stream.media-stats.label", fontAsset: fontAssetTitle)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
                .frame(height: Layout.spacing1x)

            HStack {
                Text(text: "stream.stats.name.label", fontAsset: fontAssetCaption)
                    .frame(maxWidth: 250, alignment: .leading)
                Text(text: "stream.stats.value.label", fontAsset: fontAssetCaption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
                .frame(height: Layout.spacing1x)

            ForEach(viewModel.statsItems) { item in
                HStack {
                    Text(item.key)
                        .font(theme[fontAssetTable])
                        .frame(maxWidth: 250, alignment: .leading)
                    Text(item.value)
                        .font(fontTable)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: 850)
        .padding(20)
        .background {
            Color(uiColor: UIColor.Neutral.neutral800)
                .opacity(0.7)
                .cornerRadius(Layout.cornerRadius6x)
        }
        .padding()
    }
}

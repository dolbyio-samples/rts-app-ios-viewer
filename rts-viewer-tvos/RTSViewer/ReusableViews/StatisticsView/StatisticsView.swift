//
//  StatisticsView.swift
//

import DolbyIOUIKit
import SwiftUI
import RTSComponentKit
import Foundation

struct StatisticsView: View {
    @StateObject private var viewModel: StatisticsViewModel

    init(subscriptionManager: SubscriptionManager) {
        _viewModel = StateObject(wrappedValue: StatisticsViewModel(subscriptionManager: subscriptionManager))
    }

    private let fontAssetTable = FontAsset.avenirNextRegular(size: FontSize.caption2, style: .caption2)
    private let fontTable = Font.avenirNextRegular(withStyle: .caption2, size: FontSize.caption2)

    private let fontAssetCaption = FontAsset.avenirNextDemiBold(size: FontSize.caption1, style: .caption)
    private let fontAssetTitle = FontAsset.avenirNextBold(size: FontSize.title3, style: .title3)

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

            ForEach(viewModel.statsDataList) { item in
                HStack {
                    Text(text: item.key, fontAsset: fontAssetTable)
                        .frame(maxWidth: 250, alignment: .leading)
                    Text(item.value).font(fontTable)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: 700)
        .padding([.horizontal], 35)
        .padding([.vertical], 35)
        .background(Color(uiColor: UIColor.Neutral.neutral800)).cornerRadius(Layout.cornerRadius6x)
        .padding()
    }
}

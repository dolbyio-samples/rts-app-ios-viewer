//
//  StatisticsView.swift
//

import DolbyIOUIKit
import SwiftUI
import RTSComponentKit
import Foundation

struct StatisticsView: View {
    @StateObject private var viewModel: StatisticsViewModel

    init(dataStore: RTSDataStore) {
        _viewModel = StateObject(wrappedValue: StatisticsViewModel(dataStore: dataStore))
    }

    private let fontAssetTable = FontAsset.avenirNextRegular(size: FontSize.caption1, style: .caption)
    private let fontTable = Font.avenirNextRegular(withStyle: .caption, size: FontSize.caption1)

    private let fontAssetCaption = FontAsset.avenirNextDemiBold(size: FontSize.caption1, style: .caption)
    private let fontAssetTitle = FontAsset.avenirNextBold(size: FontSize.title1, style: .title)

    var body: some View {
        VStack {
            Text(text: "stream.media-stats.label", fontAsset: fontAssetTitle)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding([.top], 30)
                .padding([.bottom], 25)

            HStack {
                Text(text: "stream.stats.name.label", fontAsset: fontAssetCaption).frame(width: 150, alignment: .leading)
                Text(text: "stream.stats.value.label", fontAsset: fontAssetCaption).frame(width: 200, alignment: .leading)
            }
            .padding([.leading], 15)

            ForEach(viewModel.data) { item in
                HStack {
                    Text(text: item.key, fontAsset: fontAssetTable).frame(width: 150, alignment: .leading)
                    Text(item.value).font(fontTable).frame(width: 200, alignment: .leading)
                }
                .padding([.top], 5)
                .padding([.leading], 15)
            }
            Spacer().frame(width: Layout.spacing1x).padding([.leading, .top], 40)
        }
    }
}

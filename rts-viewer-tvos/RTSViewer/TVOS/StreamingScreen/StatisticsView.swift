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

    private let fontAssetTable = FontAsset.avenirNextRegular(size: FontSize.caption2, style: .caption2)
    private let fontTable = Font.avenirNextRegular(withStyle: .caption2, size: FontSize.caption2)

    private let fontAssetCaption = FontAsset.avenirNextDemiBold(size: FontSize.caption1, style: .caption)
    private let fontAssetTitle = FontAsset.avenirNextBold(size: FontSize.title3, style: .title3)

    var body: some View {
        VStack {
            VStack {
                VStack {
                    HStack {
                        Text(text: "stream.media-stats.label", fontAsset: fontAssetTitle).frame(maxWidth: .infinity, alignment: .leading)
                        Spacer().frame(width: Layout.spacing1x)
                    }.padding([.leading, .top], 40).padding([.bottom], 25)
                    HStack {
                        Text(text: "stream.stats.name.label", fontAsset: fontAssetCaption).frame(maxWidth: 250, alignment: .leading)
                        Text(text: "stream.stats.value.label", fontAsset: fontAssetCaption)
                    }.frame(maxWidth: .infinity, alignment: .leading).padding([.leading, .trailing], 40).padding([.bottom], 10)
                    ForEach(viewModel.data) { item in
                        HStack {
                            Text(text: item.key, fontAsset: fontAssetTable).frame(maxWidth: 250, alignment: .leading)
                            Text(item.value).font(fontTable)
                        }.frame(maxWidth: .infinity, alignment: .leading).padding([.leading, .trailing], 40)
                    }
                    HStack {
                        Spacer().frame(width: Layout.spacing1x)
                    }.padding([.leading, .top], 40)
                }.background(Color(uiColor: UIColor.Neutral.neutral800)).cornerRadius(Layout.cornerRadius6x)
            }.frame(maxWidth: 700, maxHeight: 700).padding([.leading, .bottom], 35)
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }
}

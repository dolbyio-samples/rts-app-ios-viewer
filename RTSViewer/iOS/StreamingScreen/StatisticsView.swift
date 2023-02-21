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

    private let fontAssetTable = FontAsset.avenirNextRegular(size: FontSize.body, style: .caption)
    private let fontTable = Font.avenirNextRegular(withStyle: .body, size: FontSize.body)

    private let fontAssetCaption = FontAsset.avenirNextDemiBold(size: FontSize.caption1, style: .caption)
    private let fontAssetTitle = FontAsset.avenirNextBold(size: FontSize.title2, style: .title2)

    var body: some View {
        ScrollView {
            VStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray)
                    .frame(width: 48, height: 5)
                    .padding([.top], 5)
                Text(text: "stream.media-stats.label", fontAsset: fontAssetTitle)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding([.top], 20)
                    .padding([.bottom], 25)

                HStack {
                    Text(text: "stream.stats.name.label", fontAsset: fontAssetCaption).frame(width: 170, alignment: .leading)
                    Text(text: "stream.stats.value.label", fontAsset: fontAssetCaption).frame(width: 170, alignment: .leading)
                }
                .padding([.leading, .trailing], 15)

                ForEach(viewModel.data) { item in
                    HStack {
                        Text(text: item.key, fontAsset: fontAssetTable, textColor: Color(UIColor.Typography.Dark.secondary))
                            .frame(width: 170, alignment: .leading)
                        Text(item.value).font(fontTable)
                            .frame(width: 170, alignment: .leading)
                    }
                    .padding([.top], 5)
                    .padding([.leading, .trailing], 15)
                }
            }.padding([.bottom], 10)
        }.frame(maxWidth: 500, maxHeight: 600, alignment: .bottom)
            .background {
                Rectangle().fill(Color(uiColor: .Neutral.neutral900).opacity(0.7))
                    .ignoresSafeArea(.container, edges: .all)
            }
            .cornerRadius(Layout.cornerRadius14x)
    }
}

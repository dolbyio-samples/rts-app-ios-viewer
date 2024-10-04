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

    init(
        source: StreamSource,
        streamStatistics: MCSubscriberStats,
        layers: [MCRTSRemoteTrackLayer],
        projectedTimeStamp: Double?
    ) {
        viewModel = StatisticsViewModel(
            source: source,
            streamStatistics: streamStatistics,
            layers: layers,
            projectedTimeStamp: projectedTimeStamp
        )
    }

    private let fontAssetTable = FontAsset.avenirNextRegular(size: FontSize.caption2, style: .caption2)
    private let fontTable = Font.avenirNextRegular(withStyle: .caption2, size: FontSize.caption2)

    private let fontAssetCaption = FontAsset.avenirNextDemiBold(size: FontSize.caption1, style: .caption)
    private let fontAssetTitle = FontAsset.avenirNextBold(size: FontSize.headline, style: .headline)
    private let theme = ThemeManager.shared.theme
    @FocusState private var isFocused: Bool

    private func statsCell(for index: Int, containerViewSize: CGSize) -> some View {
        HStack {
            Text(viewModel.statsItems[index].key)
                .font(theme[fontAssetTable])
                .frame(maxWidth: containerViewSize.width * 0.35, alignment: .leading)
            Text(viewModel.statsItems[index].value)
                .font(fontTable)
        }
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                VStack {
                    FocusableView {
                        Text(text: "stream.media-stats.label", fontAsset: fontAssetTitle)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    HStack {
                        Text(text: "stream.stats.name.label", fontAsset: fontAssetCaption)
                            .frame(maxWidth: proxy.size.width * 0.35, alignment: .leading)
                        Text(text: "stream.stats.value.label", fontAsset: fontAssetCaption)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(0..<viewModel.statsItems.count, id: \.self) { index in
                        if index == viewModel.statsItems.count - 1 {
                            FocusableView {
                                statsCell(for: index, containerViewSize: proxy.size)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            HStack {
                                statsCell(for: index, containerViewSize: proxy.size)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .focusSection()
                .focused($isFocused)
                .padding()
                .background {
                    Color(uiColor: UIColor.Neutral.neutral800)
                        .opacity(isFocused ? 0.9 : 0.7)
                        .cornerRadius(Layout.cornerRadius6x)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: proxy.size.height)
        }
    }
}

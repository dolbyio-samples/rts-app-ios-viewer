//
//  ChannelVideoView.swift
//

import DolbyIOUIKit
import SwiftUI

struct ChannelVideoView: View {
    @ObservedObject var viewModel: ChannelVideoViewModel
    let width: CGFloat

    init(viewModel: ChannelVideoViewModel, width: CGFloat) {
        self.viewModel = viewModel
        self.width = width
    }

    var body: some View {
        VStack {
            let channel = viewModel.channel
            VideoRendererView(source: channel.source,
                              showSourceLabel: false,
                              showAudioIndicator: false,
                              maxWidth: width,
                              maxHeight: .infinity,
                              accessibilityIdentifier: "ChannelVideoView.\(channel.source.sourceId.displayLabel)",
                              rendererRegistry: channel.rendererRegistry)
                .overlay(alignment: .bottomTrailing) {
                    IconView(name: .settings)
                        .padding()
                        .opacity(viewModel.isFocused ? 1 : 0)
                        .animation(.easeInOut, value: viewModel.isFocused)
                }
                .overlay(alignment: .bottomLeading) {
                    if viewModel.showStatsView,
                       let streamStatistics = viewModel.statistics {
                        let videoQualityList = viewModel.videoQualityList
                        StatisticsView(
                            source: channel.source,
                            streamStatistics: streamStatistics,
                            layers: videoQualityList.compactMap {
                                switch $0 {
                                case .auto:
                                    return nil
                                case let .quality(layer):
                                    return layer
                                }
                            },
                            projectedTimeStamp: nil,
                            isMultiChannel: true
                        )
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
        }
    }
}

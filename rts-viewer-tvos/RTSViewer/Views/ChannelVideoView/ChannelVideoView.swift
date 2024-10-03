//
//  ChannelVideoView.swift
//

import DolbyIOUIKit
import SwiftUI

struct ChannelVideoView: View {
    @ObservedObject var viewModel: ChannelVideoViewModel
    let width: CGFloat

    init(viewModel: ChannelVideoViewModel, width: CGFloat) {
        print("$$$ init channelvideoview")
        self.viewModel = viewModel
        self.width = width
    }

    var body: some View {
        VStack {
            let channel = viewModel.channel
            VideoRendererView(source: channel.source,
                              isSelectedVideoSource: true,
                              isSelectedAudioSource: true,
                              showSourceLabel: false,
                              showAudioIndicator: false,
                              maxWidth: width,
                              maxHeight: .infinity,
                              accessibilityIdentifier: "ChannelVideoView.\(channel.source.sourceId.displayLabel)",
                              preferredVideoQuality: .auto,
                              subscriptionManager: channel.subscriptionManager,
                              videoTracksManager: channel.videoTracksManager)
                .overlay(alignment: .bottomTrailing) {
                    IconView(name: .settings)
                        .padding()
                        .opacity(viewModel.isFocused ? 1 : 0)
                        .animation(.easeInOut, value: viewModel.isFocused)
                }
//                .overlay(alignment: .bottomLeading) {
//                    if let streamStatistics = viewModel.streamStatistics,
//                       let mid = viewModel.channel.source.videoTrack.currentMID
//                    {
//                        let videoQualityList = viewModel.getVideoQualityList(for: channel)
//                        StatisticsView(
//                            source: channel.source,
//                            streamStatistics: streamStatistics,
//                            layers: videoQualityList.compactMap {
//                                switch $0 {
//                                case .auto:
//                                    return nil
//                                case let .quality(layer):
//                                    return layer
//                                }
//                            },
//                            projectedTimeStamp: nil
//                        )
//                    }
//                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
        }
    }
}

// #Preview {
//    ChannelVideoView()
// }

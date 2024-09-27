//
//  ChannelGridView.swift
//

import DolbyIOUIKit
import MillicastSDK
import RTSCore
import SwiftUI

struct ChannelGridView: View {
    static let numberOfColumns = 2
    @ObservedObject var viewModel: ChannelGridViewModel
    @State var showSettingsView: Bool = false

    init(viewModel: ChannelGridViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        GeometryReader { proxy in
            let screenSize = proxy.size
            let tileWidth = screenSize.width / CGFloat(Self.numberOfColumns)
            let columns = [GridItem](repeating: GridItem(.flexible(), spacing: Layout.spacing1x), count: Self.numberOfColumns)

            LazyVGrid(columns: columns, alignment: .leading) {
                ForEach(Array(viewModel.channels.enumerated()), id: \.offset) { index, channel in
                    let source = channel.source
                    let preferredVideoQuality: VideoQuality = .auto
                    let displayLabel = source.sourceId.displayLabel
                    let viewId = "\(ChannelGridView.self).\(displayLabel)"
                    let focusedRendererViewModel = FocusedRendererViewModel(channel: channel, currentlyFocusedChannel: $viewModel.currentlyFocusedChannel, isFocused: index == 0)

                    FocusableVideoRendererView(viewModel: focusedRendererViewModel, width: tileWidth, height: .infinity)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
                        .onAppear {
                            ChannelGridViewModel.logger.debug("♼ Channel Grid view: Video view appear for \(source.sourceId)")
                            Task {
                                await channel.videoTracksManager.enableTrack(for: source, with: preferredVideoQuality, on: viewId)
                            }
                        }
                        .onDisappear {
                            ChannelGridViewModel.logger.debug("♼ Channel Grid view: Video view disappear for \(source.sourceId)")
                            Task {
                                await channel.videoTracksManager.disableTrack(for: source, on: viewId)
                            }
                        }
                        .id(source.id)
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
//            .overlay(alignment: .trailing) {
//                if showSettingsView {
//                    SettingsView(
//                        source: source,
//                        showStatsView: $showStatsView,
//                        showLiveIndicator: Binding(get: {
//                            viewModel.isLiveIndicatorEnabled
//                        }, set: {
//                            viewModel.updateLiveIndicator($0)
//                        }),
//                        videoQualityList: viewModel.videoQualityList,
//                        selectedVideoQuality: viewModel.selectedVideoQuality,
//                        rendererRegistry: viewModel.rendererRegistry,
//                        onSelectVideoQuality: { source, videoQuality in
//                            viewModel.select(videoQuality: videoQuality, for: source)
//                        }
//                    )
//                }
//            }
        }
    }
}

#Preview {
    ChannelGridView(viewModel: ChannelGridViewModel(channels: []))
}

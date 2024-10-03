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
    @FocusState var focusedView: FocusedView?
    @State private var showSettingsView = false
    @State private var showStatsView = false

    enum FocusedView: Hashable, Equatable {
        case gridView(SourcedChannel)
        case settings
    }

    init(viewModel: ChannelGridViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        BackgroundContainerView {
            GeometryReader { proxy in
                let screenSize = proxy.size
                let tileWidth = screenSize.width / CGFloat(Self.numberOfColumns)
                let columns = [GridItem](repeating: GridItem(.flexible(), spacing: Layout.spacing1x), count: Self.numberOfColumns)

                LazyVGrid(columns: columns, alignment: .leading) {
                    ForEach(viewModel.channels) { channel in
                        Button {
                            viewModel.currentlyFocusedChannel = channel
                            showSettingsView.toggle()
                        } label: {
                            let channelVideoViewModel = ChannelVideoViewModel(channel: channel, focusedChannel: $viewModel.currentlyFocusedChannel)
                            ChannelVideoView(viewModel: channelVideoViewModel, width: tileWidth)
                        }
                        .focused($focusedView, equals: .gridView(channel))
                        .disabled(showSettingsView)
                        .buttonStyle(GridButtonStyle(focusedView: focusedView, currentChannel: channel, focusedBorderColor: .purple))
                        .onAppear {
                            viewModel.enableVideo(for: channel)
                        }
                        .onDisappear {
                            viewModel.disableVideo(for: channel)
                        }
                        .id(channel.source.id)
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
                .overlay(alignment: .trailing) {
                    if showSettingsView {
                        settingsView(for: viewModel.currentlyFocusedChannel)
                            .focused($focusedView, equals: .settings)
                    }
                }
                .onChange(of: focusedView ?? .settings) { focus in
                    if case let .gridView(focusedChannel) = focus {
                        viewModel.updateFocus(with: focusedChannel)
                    }
                }
            }
        }
    }

    @ViewBuilder
    func settingsView(for channel: SourcedChannel) -> some View {
        let qualityList = viewModel.getVideoQualityList(for: channel)
        let selectedQuality = viewModel.getSelectedQuality(for: channel)
        let settingViewModel = SettingsMultichannelViewModel(channel: channel,
                                                             videoQualityList: qualityList,
                                                             selectedVideoQuality: selectedQuality)
        SettingsMultichannelView(viewModel: settingViewModel, showSettingsView: $showSettingsView, showStatsView: $showStatsView) { channel, quality in
            viewModel.enableVideo(for: channel, with: quality)
        }
    }
}

#Preview {
    ChannelGridView(viewModel: ChannelGridViewModel(channels: []))
}

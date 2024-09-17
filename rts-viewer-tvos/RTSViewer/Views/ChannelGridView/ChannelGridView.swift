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
        case gridView(Channel)
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
                    ForEach(Array(viewModel.channels.enumerated()), id: \.offset) { _, channel in
                        Button {
                            withAnimation {
                                showSettingsView.toggle()
                            }
                        } label: {
                            let channelVideoViewModel = ChannelVideoViewModel(channel: channel)
                            ChannelVideoView(viewModel: channelVideoViewModel, width: tileWidth)
                        }
                        .focused($focusedView, equals: .gridView(channel))
                        .disabled(showSettingsView)
                        .buttonStyle(GridButtonStyle(focusedView: focusedView, currentChannel: channel, focusedBorderColor: .purple))
                        .onAppear {
                            viewModel.onAppear(for: channel)
                        }
                        .onDisappear {
                            viewModel.onDisappear(for: channel)
                        }
                        .id(channel.source.id)
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
                .overlay(alignment: .trailing) {
                    if showSettingsView,
                       let currentlyFocusedChannel = viewModel.getCurrentlyFocusedChannel() {
                        settingsView(for: currentlyFocusedChannel)
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
    func settingsView(for channel: Channel) -> some View {
        let settingViewModel = SettingsMultichannelViewModel(channel: channel)
        SettingsMultichannelView(viewModel: settingViewModel, showSettingsView: $showSettingsView, showStatsView: channel.showStatsView)
    }
}

#Preview {
    ChannelGridView(viewModel: ChannelGridViewModel(channels: []))
}

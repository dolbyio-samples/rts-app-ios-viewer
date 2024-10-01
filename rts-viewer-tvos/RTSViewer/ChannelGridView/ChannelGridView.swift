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
    @State private var showSettingsView: Bool = false
    @State private var showStatsView = false

    enum FocusedView: Hashable, Equatable {
        case gridView(SourcedChannel)
        case settings
    }

    init(viewModel: ChannelGridViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        GeometryReader { proxy in
            let screenSize = proxy.size
            let tileWidth = screenSize.width / CGFloat(Self.numberOfColumns)
            let columns = [GridItem](repeating: GridItem(.flexible(), spacing: Layout.spacing1x), count: Self.numberOfColumns)

            LazyVGrid(columns: columns, alignment: .leading) {
                ForEach(viewModel.channels) { channel in
                    Button {
                        showSettingsView.toggle()
                    } label: {
                        focusedVideoView(channel: channel, width: tileWidth)
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
                    let settingViewModel = SettingMultichannelViewModel(channel: viewModel.currentlyFocusedChannel)
                    SettingsMultichannelView(viewModel: settingViewModel, showSettingsView: $showSettingsView, showStatsView: $showStatsView) { _, _ in
                        print("change quality of selected")
                    }
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

    @ViewBuilder
    func focusedVideoView(channel: SourcedChannel, width: CGFloat) -> some View {
        let isFocused = channel == viewModel.currentlyFocusedChannel
        VideoRendererView(source: channel.source,
                          isSelectedVideoSource: true,
                          isSelectedAudioSource: true,
                          showSourceLabel: false,
                          showAudioIndicator: false,
                          maxWidth: width,
                          maxHeight: .infinity,
                          accessibilityIdentifier: "ChannelGridViewVideoTile.\(channel.source.sourceId.displayLabel)",
                          preferredVideoQuality: .auto,
                          subscriptionManager: channel.subscriptionManager,
                          videoTracksManager: channel.videoTracksManager)
            .overlay(alignment: .bottomTrailing) {
                let isFocused = viewModel.isFocusedChannel(focusedView: focusedView, currentChannel: channel)

                IconView(name: .settings)
                    .padding()
                    .opacity(isFocused ? 1 : 0)
                    .animation(.easeInOut, value: isFocused)
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
    }
}

#Preview {
    ChannelGridView(viewModel: ChannelGridViewModel(channels: []))
}

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
                ForEach(Array(viewModel.channels.enumerated()), id: \.offset) { _, channel in
                    let source = channel.source
                    let preferredVideoQuality: VideoQuality = .auto
                    let displayLabel = source.sourceId.displayLabel
                    let viewId = "\(ChannelGridView.self).\(displayLabel)"

                    Button {
                        showSettingsView.toggle()
                    } label: {
                        focusedVideoView(channel: channel, width: tileWidth)
                    }
                    .focused($focusedView, equals: .gridView(channel))

                    .disabled(showSettingsView)
                    .buttonStyle(GridButtonStyle(focusedView: focusedView, currentChannel: channel, focusedBorderColor: .purple))
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
            .overlay(alignment: .trailing) {
                if showSettingsView {
                    let settingViewModel = SettingMultichannelViewModel(channel: viewModel.currentlyFocusedChannel)
                    SettingsMultichannelView(viewModel: settingViewModel, showSettingsView: $showSettingsView, showStatsView: $showStatsView) { _, _ in
                        print("change quality of selected")
                    }
                    .focused($focusedView, equals: .settings)
                }
            }
        }

        .onChange(of: focusedView ?? .settings) { focus in
            if case let .gridView(focusedChannel) = focus {
                viewModel.updateFocus(with: focusedChannel)
            }
        }
    }

    @ViewBuilder
    func focusedVideoView(channel: SourcedChannel, width: CGFloat) -> some View {
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
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
    }
}

#Preview {
    ChannelGridView(viewModel: ChannelGridViewModel(channels: []))
}

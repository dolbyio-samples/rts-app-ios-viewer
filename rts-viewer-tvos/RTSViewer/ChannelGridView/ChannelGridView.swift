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
    @State private var showStatsView = false

    @FocusState var overlayIsFocused: Bool
    @FocusState var focusedChannel: SourcedChannel?

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
                    let focusedRendererViewModel = FocusedRendererViewModel(channel: channel, currentlyFocusedChannel: $viewModel.currentlyFocusedChannel)
                    FocusableVideoRendererView(viewModel: focusedRendererViewModel,
                                               showSettingsView: $showSettingsView,
                                               width: tileWidth,
                                               height: .infinity,
                                               isFocused: index == 0)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
                        .onLongPressGesture(minimumDuration: 0.1, perform: {
                            showSettingsView.toggle()
                            print("$$$ open/close settings")
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                overlayIsFocused = true
                            }
                        })
                        .focused($focusedChannel, equals: channel)
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
//                    let settingViewModel = SettingMultichannelViewModel(channel: viewModel.currentlyFocusedChannel)
//                    SettingsMultichannelView(viewModel: settingViewModel, overlayIsFocused: $overlayIsFocused, showStatsView: $showStatsView) { _, _ in
//                        print("change quality of selected")
//                    }
//                    .focused($overlayIsFocused)
                }
            }
        }
    }
}

#Preview {
    ChannelGridView(viewModel: ChannelGridViewModel(channels: []))
}

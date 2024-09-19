//
//  ChannelGridView.swift
//

import DolbyIOUIKit
import MillicastSDK
import RTSCore
import SwiftUI

struct ChannelGridView: View {
    private let viewModel: ChannelGridViewModel

    static let numberOfColumns = 2

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
                    let source = channel.source
                    let preferredVideoQuality: VideoQuality = .auto
                    let displayLabel = source.sourceId.displayLabel
                    let viewId = "\(ChannelGridView.self).\(displayLabel)"
                    VideoRendererView(source: source,
                                      isSelectedVideoSource: true,
                                      isSelectedAudioSource: true,
                                      showSourceLabel: false,
                                      showAudioIndicator: false,
                                      maxWidth: tileWidth,
                                      maxHeight: .infinity,
                                      accessibilityIdentifier: "ChannelGridViewVideoTile.\(source.sourceId.displayLabel)",
                                      preferredVideoQuality: preferredVideoQuality,
                                      subscriptionManager: channel.subscriptionManager,
                                      videoTracksManager: channel.videoTracksManager)
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
                        .id(channel.source.id)
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
        }
    }
}

#Preview {
    ChannelGridView(viewModel: ChannelGridViewModel(channels: []))
}

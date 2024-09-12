//
//  ChannelGridView.swift
//  Interactive Player
//

import DolbyIOUIKit
import MillicastSDK
import RTSCore
import SwiftUI

struct ChannelGridView: View {
    @State private var deviceOrientation: UIDeviceOrientation = .portrait

    private let viewModel: ChannelGridViewModel

    private enum Defaults {
        static let numberOfColumnsForPortrait = 1
        static let numberOfColumnsForLandscape = 2
    }

    init(viewModel: ChannelGridViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        GeometryReader { proxy in
            let screenSize = proxy.size
            let numberOfColumns = deviceOrientation.isPortrait ? Defaults.numberOfColumnsForPortrait : Defaults.numberOfColumnsForLandscape
            let tileWidth = screenSize.width / CGFloat(numberOfColumns)
            let columns = [GridItem](repeating: GridItem(.flexible(), spacing: Layout.spacing1x), count: numberOfColumns)
            ScrollView {
                LazyVGrid(columns: columns, alignment: .leading) {
                    ForEach(viewModel.channels) { channel in
                        let source = channel.source
                        let displayLabel = source.sourceId.displayLabel
                        let preferredVideoQuality: VideoQuality = .auto

                        let viewId = "\(ChannelGridView.self).\(displayLabel)"

                        VideoRendererView(
                            source: source,
                            isSelectedVideoSource: true,
                            isSelectedAudioSource: true,
                            isPiPView: false,
                            showSourceLabel: false,
                            showAudioIndicator: false,
                            maxWidth: tileWidth,
                            maxHeight: .infinity,
                            accessibilityIdentifier: "ChannelGridViewVideoTile.\(source.sourceId.displayLabel)",
                            preferredVideoQuality: preferredVideoQuality,
                            subscriptionManager: channel.subscriptionManager,
                            videoTracksManager: channel.videoTracksManager,
                            action: { _ in }
                        )
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
                        .onAppear {
                            GridViewModel.logger.debug("♼ Channel Grid view: Video view appear for \(source.sourceId)")
                            Task {
                                await channel.videoTracksManager.enableTrack(for: source, with: preferredVideoQuality, on: viewId)
                            }
                        }
                        .onDisappear {
                            GridViewModel.logger.debug("♼ Channel Grid view: Video view disappear for \(source.sourceId)")
                            Task {
                                await channel.videoTracksManager.disableTrack(for: source, on: viewId)
                            }
                        }
                        .id(source.id)
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
            }
            .onRotate { newOrientation in
                if !newOrientation.isFlat && newOrientation.isValidInterfaceOrientation {
                    deviceOrientation = newOrientation
                }
            }
        }
    }
}

 #Preview {
    ChannelGridView(viewModel: ChannelGridViewModel(channels: []))
 }

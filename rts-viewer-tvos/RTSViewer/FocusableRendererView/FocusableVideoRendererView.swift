//
//  FocusableItemView.swift
//

import SwiftUI

struct FocusableVideoRendererView: View {
    @ObservedObject var viewModel: FocusedRendererViewModel
    let width: CGFloat
    let height: CGFloat

    init(viewModel: FocusedRendererViewModel, width: CGFloat, height: CGFloat) {
        self.viewModel = viewModel
        self.width = width
        self.height = height
    }

    var body: some View {
        ZStack {
            videoRendererView
                .border(viewModel.isFocused ? .purple : .gray, width: 2)
        }
        .focusable(true) { isFocused in
            self.viewModel.isFocused = isFocused
            viewModel.updateFocus(with: isFocused)
        }
        .animation(.easeInOut, value: viewModel.isFocused)
    }

    @ViewBuilder
    private var videoRendererView: some View {
        let channel = viewModel.channel
        VideoRendererView(source: channel.source,
                          isSelectedVideoSource: true,
                          isSelectedAudioSource: true,
                          showSourceLabel: false,
                          showAudioIndicator: false,
                          maxWidth: width,
                          maxHeight: height,
                          accessibilityIdentifier: "ChannelGridViewVideoTile.\(channel.source.sourceId.displayLabel)",
                          preferredVideoQuality: .auto,
                          subscriptionManager: channel.subscriptionManager,
                          videoTracksManager: channel.videoTracksManager)
    }
}

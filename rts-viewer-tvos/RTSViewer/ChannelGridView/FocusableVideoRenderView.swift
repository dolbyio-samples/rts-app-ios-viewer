//
//  FocusableItemView.swift
//

import SwiftUI

struct FocusableVideoRenderView: View {
    @State private var isFocused: Bool = false
    let channel: SourcedChannel
    let width: CGFloat
    let height: CGFloat

    init(channel: SourcedChannel, width: CGFloat, height: CGFloat) {
        self.channel = channel
        self.width = width
        self.height = height
    }

    var body: some View {
        ZStack {
            videoRendererView
                .border(isFocused ? .purple : .gray, width: 2)
        }
        .focusable(true) { isFocused in
            self.isFocused = isFocused
        }
        .animation(.easeInOut, value: isFocused)
    }

    @ViewBuilder
    private var videoRendererView: some View {
        VideoRendererView(source: channel.source,
                          isSelectedVideoSource: true,
                          isSelectedAudioSource: channel.enableSound,
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

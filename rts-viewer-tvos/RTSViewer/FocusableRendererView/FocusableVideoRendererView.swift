//
//  FocusableItemView.swift
//

import DolbyIOUIKit
import SwiftUI

struct FocusableVideoRendererView: View {
    @ObservedObject var viewModel: FocusedRendererViewModel
    @Binding var showSettingsView: Bool
    @State var isFocused: Bool
    let width: CGFloat
    let height: CGFloat

    init(viewModel: FocusedRendererViewModel, showSettingsView: Binding<Bool>, width: CGFloat, height: CGFloat, isFocused: Bool) {
        self.viewModel = viewModel
        self._showSettingsView = showSettingsView
        self.width = width
        self.height = height
        self.isFocused = isFocused
    }

    var body: some View {
        ZStack {
            videoRendererView
                .border(isFocused ? .purple : .gray, width: 2)
        }
        .focusable(true) { isFocused in
            self.isFocused = isFocused
            viewModel.updateFocus(with: isFocused)
        }
        .animation(.easeInOut, value: isFocused)
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
        .overlay(alignment: .bottomTrailing) {
            IconView(name: .settings)
                .padding()
                .opacity(isFocused ? 1 : 0)
                .animation(.easeInOut, value: isFocused)
        }
    }
}

//
//  LandingView.swift
//

import DolbyIORTSCore
import DolbyIOUIKit
import DolbyIORTSUIKit
import SwiftUI

struct Stream {
    let selectedStream: StreamDetail
    let listViewVideoQuality: DolbyIORTSUIKit.VideoQuality
}

struct LandingView: View {
    @StateObject private var viewModel: LandingViewModel = .init()
    @StateObject private var recentStreamsViewModel: RecentStreamsViewModel = RecentStreamsViewModel()

    @State private var isShowingStreamInputView = false
    @State private var isShowingFullStreamHistoryView: Bool = false
    @State private var isShowingSettingsView: Bool = false
    @State private var streamingScreenContext: StreamingView.Context?

    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            NavigationLink(
                destination: StreamDetailInputScreen(streamingScreenContext: $streamingScreenContext),
                isActive: $isShowingStreamInputView) {
                    EmptyView()
                }
                .hidden()

            NavigationLink(
                destination: SavedStreamsScreen(viewModel: recentStreamsViewModel),
                isActive: $isShowingFullStreamHistoryView) {
                    EmptyView()
                }
                .hidden()

            NavigationLink(
                destination: SettingsScreen(mode: .global, moreSettings: {
                    AppSettingsView()
                }),
                isActive: $isShowingSettingsView) {
                    EmptyView()
                }
                .hidden()

            if viewModel.hasSavedStreams {
                RecentStreamsScreen(
                    viewModel: recentStreamsViewModel,
                    isShowingStreamInputView: $isShowingStreamInputView,
                    isShowingFullStreamHistoryView: $isShowingFullStreamHistoryView,
                    isShowingSettingsView: $isShowingSettingsView,
                    streamingScreenContext: $streamingScreenContext
                )
            } else {
                StreamDetailInputScreen(streamingScreenContext: $streamingScreenContext)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                IconView(iconAsset: .dolby_logo_dd, tintColor: .white)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                SettingsButton { isShowingSettingsView = true }
                    .accessibilityIdentifier(
                        viewModel.hasSavedStreams
                        ? "RecentScreen.SettingButton"
                        : "InputScreen.SettingButton"
                    )
            }

            ToolbarItem(placement: .bottomBar) {
                FooterView(text: "recent-streams.footnote.label")
            }
        }
        .layoutPriority(1)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .id(appState.rootViewID)
        .onAppear {
            viewModel.startStreamObservations()
        }
        .fullScreenCover(item: $streamingScreenContext) { context in
            StreamingView(context: context) {
                streamingScreenContext = nil
            }
        }
    }
}

struct LandingView_Previews: PreviewProvider {
    static var previews: some View {
        LandingView()
    }
}

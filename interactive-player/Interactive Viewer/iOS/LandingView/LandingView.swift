//
//  LandingView.swift
//

import DolbyIORTSCore
import DolbyIOUIKit
import DolbyIORTSUIKit
import SwiftUI

struct LandingView: View {
    @StateObject private var viewModel: LandingViewModel = .init()
    @StateObject private var recentStreamsViewModel: RecentStreamsViewModel = .init()

    @State private var isShowingStreamInputView = false
    @State private var isShowingFullStreamHistoryView: Bool = false
    @State private var isShowingSettingScreenView: Bool = false
    @State private var playedStreamDetail: DolbyIORTSCore.StreamDetail?

    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            NavigationLink(
                destination: LazyNavigationDestinationView(
                    StreamDetailInputScreen(
                        isShowingSettingScreenView: $isShowingSettingScreenView,
                        playedStreamDetail: $playedStreamDetail
                    )
                ),
                isActive: $isShowingStreamInputView) {
                    EmptyView()
                }
                .hidden()

            NavigationLink(
                destination: LazyNavigationDestinationView(SavedStreamsScreen(viewModel: recentStreamsViewModel)),
                isActive: $isShowingFullStreamHistoryView) {
                    EmptyView()
                }
                .hidden()

            NavigationLink(
                destination: LazyNavigationDestinationView(SettingsScreen(mode: .global)),
                isActive: $isShowingSettingScreenView) {
                    EmptyView()
                }
                .hidden()

            RecentStreamsScreen(
                viewModel: recentStreamsViewModel,
                isShowingStreamInputView: $isShowingStreamInputView,
                isShowingFullStreamHistoryView: $isShowingFullStreamHistoryView,
                isShowingSettingScreenView: $isShowingSettingScreenView,
                playedStreamDetail: $playedStreamDetail
            )
            .opacity(viewModel.hasSavedStreams ? 1 : 0)

            StreamDetailInputScreen(
                isShowingSettingScreenView: $isShowingSettingScreenView,
                playedStreamDetail: $playedStreamDetail
            )
            .opacity(viewModel.hasSavedStreams ? 0 : 1)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                IconView(iconAsset: .dolby_logo_dd, tintColor: .white)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                IconButton(iconAsset: .settings, action: {
                    isShowingSettingScreenView = true
                }).scaleEffect(0.5, anchor: .trailing)
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
        .fullScreenCover(item: $playedStreamDetail) { streamDetail in
            StreamingScreen(streamDetail: streamDetail) {
                playedStreamDetail = nil
            }
        }
    }
}

struct LandingView_Previews: PreviewProvider {
    static var previews: some View {
        LandingView()
    }
}

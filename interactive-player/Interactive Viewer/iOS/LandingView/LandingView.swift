//
//  LandingView.swift
//

import DolbyIOUIKit
import DolbyIORTSUIKit
import SwiftUI

struct LandingView: View {
    @StateObject private var viewModel: LandingViewModel = .init()
    @StateObject private var recentStreamsViewModel: RecentStreamsViewModel = .init()

    @State private var isShowingStreamInputView = false
    @State private var isShowingStreamingView: Bool = false
    @State private var isShowingFullStreamHistoryView: Bool = false
    @State private var isShowingSettingScreenView: Bool = false

    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            NavigationLink(
                destination: LazyNavigationDestinationView(
                    StreamDetailInputScreen(
                        isShowingSettingScreenView: $isShowingSettingScreenView,
                        isShowingStreamingView: $isShowingStreamingView
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
                isShowingStreamingView: $isShowingStreamingView,
                isShowingFullStreamHistoryView: $isShowingFullStreamHistoryView,
                isShowingSettingScreenView: $isShowingSettingScreenView
            )
            .opacity(viewModel.hasSavedStreams ? 1 : 0)

            StreamDetailInputScreen(
                isShowingSettingScreenView: $isShowingSettingScreenView,
                isShowingStreamingView: $isShowingStreamingView
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
        .fullScreenCover(isPresented: $isShowingStreamingView) {
            StreamingScreen(isShowingStreamView: $isShowingStreamingView)
        }
    }
}

struct LandingView_Previews: PreviewProvider {
    static var previews: some View {
        LandingView()
    }
}

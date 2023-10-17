//
//  LandingView.swift
//

import DolbyIORTSCore
import DolbyIOUIKit
import DolbyIORTSUIKit
import SwiftUI

struct Stream {
    let selectedStream: StreamDetail
    let listViewVideoQuality: VideoQuality
}

struct LandingView: View {
    @StateObject private var viewModel: LandingViewModel = .init()
    @StateObject private var recentStreamsViewModel: RecentStreamsViewModel = .init()

    @State private var isShowingStreamInputView = false
    @State private var isShowingFullStreamHistoryView: Bool = false
    @State private var isShowingSettingsView: Bool = false
    @State private var streamingScreenContext: StreamingScreen.Context?

    @EnvironmentObject private var appState: AppState
    @AppConfiguration(\.showDebugFeatures) var showDebugFeatures

    var body: some View {
        ZStack {
            NavigationLink(
                destination: LazyNavigationDestinationView(
                    StreamDetailInputScreen(
                        isShowingSettingsView: $isShowingSettingsView,
                        streamingScreenContext: $streamingScreenContext
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
                destination: LazyNavigationDestinationView(
                    SettingsScreen(mode: .global, moreSettings: {
                        // Custom App Configurations
                        Toggle(isOn: $showDebugFeatures) {
                            Text(
                                "app-configuration-show-debug-features-label",
                                style: .titleMedium,
                                font: .custom("AvenirNext-Regular", size: FontSize.body)
                            )
                        }
                    })
                ),
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
                StreamDetailInputScreen(
                    isShowingSettingsView: $isShowingSettingsView,
                    streamingScreenContext: $streamingScreenContext
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                IconView(iconAsset: .dolby_logo_dd, tintColor: .white)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                SettingsButton { isShowingSettingsView = true }
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
            StreamingScreen(
                context: context,
                listViewPrimaryVideoQuality: .high
            ) {
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

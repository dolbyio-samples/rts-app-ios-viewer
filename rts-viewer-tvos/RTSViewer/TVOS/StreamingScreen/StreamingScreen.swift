//
//  StreamingScreen.swift
//

import DolbyIOUIKit
import SwiftUI
import RTSComponentKit
import Network
import MillicastSDK

struct StreamingScreen: View {

    @StateObject private var viewModel: DisplayStreamViewModel

    @State private var showToolbar = false
    @State private var showSettingsView = false
    @State private var showSimulcastView = false
    @State private var showStatsView = false

    @Environment(\.dismiss) var dismiss

    init(dataStore: RTSDataStore) {
        _viewModel = StateObject(wrappedValue: DisplayStreamViewModel(dataStore: dataStore))
    }

    var blackTranslucentAlpha: CGFloat {
        switch (viewModel.isStreamActive, showToolbar) {
        case (false, _):
            return 0.8
        case (true, true):
            return 0.5
        default:
            return 0.0
        }
    }

    var body: some View {
        BackgroundContainerView {
            ZStack {
                if let videoTrack = viewModel.videoTrack {
                    VideoView(videoTrack: videoTrack)
                }

                VStack {}
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                    .opacity(blackTranslucentAlpha)

                StreamingToolbarView(
                    dataStore: viewModel.dataStore,
                    isStreamActive: viewModel.isStreamActive,
                    isLiveIndicatorEnabled: viewModel.isLiveIndicatorEnabled,
                    showSettingsView: $showSettingsView
                )

                if showSettingsView {
                    SettingsView(
                        videoQualityList: viewModel.videoQualityList,
                        selectedVideoQuality: viewModel.selectedVideoQuality,
                        dataStore: viewModel.dataStore,
                        showSimulcastView: $showSimulcastView,
                        showStatsView: $showStatsView,
                        showLiveIndicator: Binding(get: {
                            viewModel.isLiveIndicatorEnabled
                        }, set: {
                            viewModel.updateLiveIndicator($0)
                        })
                    )
                }

                if !viewModel.isStreamActive {
                    StreamConnectionView(isNetworkConnected: viewModel.isNetworkConnected)
                }

                if showStatsView {
                    StatisticsView(dataStore: viewModel.dataStore)
                }
            }
            .edgesIgnoringSafeArea(.all)
            .onReceive(viewModel.$isStreamActive) { isStreamActive in
                Task {
                    UIApplication.shared.isIdleTimerDisabled = isStreamActive
                }
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = viewModel.isStreamActive
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            Task {
                try await viewModel.stopSubscribe()
            }
        }
        .navigationBarHidden(true)
        .onExitCommand {
            if showSimulcastView {
                showSimulcastView = false
            } else if showSettingsView {
                showSettingsView = false
            } else {
                dismiss()
            }
        }
    }
}

#if DEBUG
struct StreamingScreen_Previews: PreviewProvider {
    static var previews: some View {
        StreamingScreen(dataStore: .init())
    }
}
#endif

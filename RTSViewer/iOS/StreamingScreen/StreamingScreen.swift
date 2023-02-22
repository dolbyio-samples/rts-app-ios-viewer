//
//  StreamingScreen.swift
//  RTSViewer
//

import DolbyIOUIKit
import SwiftUI
import RTSComponentKit
import Network

struct StreamingScreen: View {

    @StateObject private var viewModel: DisplayStreamViewModel
    @StateObject private var toolbarViewModel: StreamToolbarViewModel

    @State private var showToolbar = false
    @State private var showSettings = false
    @State private var showSimulcastView = false
    @State private var showStats = false
    @State private var showFullScreen = false

    init(dataStore: RTSDataStore) {
        _viewModel = StateObject(wrappedValue: DisplayStreamViewModel(dataStore: dataStore))
        _toolbarViewModel = StateObject(wrappedValue: StreamToolbarViewModel(dataStore: dataStore))
    }

    var body: some View {
        ZStack {
            ZStack {
                VideoView(viewModel: viewModel, showFullScreen: showFullScreen)

                VStack {}
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                    .opacity(viewModel.isStreamActive ? (showToolbar ? 0.5: 0.0) : 0.8)

                StreamingToolbarView(viewModel: toolbarViewModel, showSimulcast: !viewModel.layersDisabled, showSettings: $showSettings, showToolbar: $showToolbar, showStats: $showStats, showFullScreen: $showFullScreen, onChangeFullScreen: { fullScreen in
                    viewModel.updateScreenSize(crop: fullScreen, width: nil, height: nil)
                })
            }
            .edgesIgnoringSafeArea(.all)
            .onReceive(viewModel.$isStreamActive) { isStreamActive in
                Task {
                    UIApplication.shared.isIdleTimerDisabled = isStreamActive
                }
            }
            .background(Color(uiColor: UIColor.Neutral.neutral900))
            .simultaneousGesture(
                showSettings || showStats ? TapGesture().onEnded {
                    showSettings = false
                    showStats = false
                } : nil)

            if showSettings {
                SettingsView(
                    disableLayers: viewModel.layersDisabled,
                    activeStreamTypes: viewModel.activeStreamTypes,
                    selectedLayer: viewModel.selectedLayer,
                    showSimulcastView: $showSimulcastView,
                    statsView: $showStats,
                    showLiveIndicator: $toolbarViewModel.isLiveIndicatorEnabled,
                    showSettings: $showSettings,
                    dataStore: viewModel.dataStore
                )
            }
            if !viewModel.isStreamActive {
                StreamConnectionView(isNetworkConnected: viewModel.isNetworkConnected)
            }

        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = viewModel.isStreamActive
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            Task {
                await viewModel.stopSubscribe()
            }
        }
        .navigationBarHidden(true)
        .statusBarHidden(true)
    }

    private func hideToolbar() {
        withAnimation {
            showToolbar = false
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

//
//  StreamingScreen.swift
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
                VideoView(streamingView: viewModel.streamingView,
                          width: viewModel.width,
                          height: viewModel.height,
                          updateScreenSize: { (width: Float, height: Float) in
                    viewModel.updateScreenSize(width: width, height: height)
                })

                VStack {}
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                    .opacity(viewModel.isStreamActive && viewModel.isNetworkConnected ? (showToolbar ? 0.5: 0.0) : 0.8)
            }
            .edgesIgnoringSafeArea(.all)
            .onReceive(viewModel.$isStreamActive) { isStreamActive in
                Task {
                    UIApplication.shared.isIdleTimerDisabled = isStreamActive
                }
            }
            .background(Color(uiColor: UIColor.Neutral.neutral900))

            StreamingToolbarView(
                viewModel: toolbarViewModel,
                showSimulcast: !viewModel.layersDisabled,
                showSettings: $showSettings,
                showToolbar: $showToolbar,
                showStats: $showStats,
                showFullScreen: $showFullScreen,
                onChangeFullScreen: { fullScreen in
                    viewModel.showVideoInFullScreen(fullScreen)
                }
            )
            .simultaneousGesture(
                showSettings || showStats ? DragGesture(minimumDistance: 0).onEnded { _ in
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

            if showStats {
                HStack {
                    StatisticsView(dataStore: viewModel.dataStore)
                        .background(RemoveBackgroundColor())

                    Spacer()
                }
                .ignoresSafeArea(.all)
                .frame(maxHeight: .infinity, alignment: .bottom)
            }

            if !viewModel.isStreamActive || !viewModel.isNetworkConnected {
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

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

    @State private var volume = 0.5
    @State private var showToolbar = false
    @State private var showSettings = false
    @State private var showSimulcastView = false
    @State private var showStats = false

    @Environment(\.dismiss) var dismiss

    init(dataStore: RTSDataStore) {
        _viewModel = StateObject(wrappedValue: DisplayStreamViewModel(dataStore: dataStore))
        _toolbarViewModel = StateObject(wrappedValue: StreamToolbarViewModel(dataStore: dataStore))
    }

    var body: some View {
        BackgroundContainerView {
            ZStack {
                let screenRect = UIScreen.main.bounds
                let (videoFrameWidth, videoFrameHeight) = viewModel.calculateVideoViewWidthHeight(screenWidth: Float(screenRect.size.width), screenHeight: Float(screenRect.size.height))
                GeometryReader { geometry in
                    VideoRendererView(uiView: viewModel.streamingView)
                        .frame(width: videoFrameWidth, height: videoFrameHeight)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }

                VStack {}
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                    .opacity(viewModel.isStreamActive ? (showToolbar ? 0.5: 0.0) : 0.8)

                StreamingTopToolbarView(viewModel: toolbarViewModel, showSettings: $showSettings, showToolbar: $showToolbar)

                StreamingBottomToolbarView(viewModel: toolbarViewModel, !viewModel.layersDisabled, showSettings: $showSettings, showToolbar: $showToolbar, $showStats)

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
                    if viewModel.isNetworkConnected {
                        VStack {
                            Text(
                                text: "stream.offline.title.label",
                                fontAsset: .avenirNextDemiBold(
                                    size: FontSize.title3,
                                    style: .title3
                                )
                            )
                            Text(
                                text: "stream.offline.subtitle.label",
                                fontAsset: .avenirNextRegular(
                                    size: FontSize.caption2,
                                    style: .caption2
                                )
                            )
                        }
                    } else {
                        Text(
                            text: "stream.network.disconnected.label",
                            fontAsset: .avenirNextDemiBold(
                                size: FontSize.title3,
                                style: .title3
                            )
                        )

                    }
                }

                if showStats {
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
                await viewModel.stopSubscribe()
            }
        }
        .navigationBarHidden(true)
#if os(tvOS)
        .onExitCommand {
            if showSimulcastView {
                showSimulcastView = false
            } else if showSettings {
                showSettings = false
            } else if showToolbar {
                hideToolbar()
            } else {
                dismiss()
            }
        }
#endif
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

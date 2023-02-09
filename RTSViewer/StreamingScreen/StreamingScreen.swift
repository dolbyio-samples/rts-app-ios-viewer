//
//  StreamingScreen.swift
//  RTSViewer
//

import DolbyIOUIKit
import SwiftUI
import RTSComponentKit
import Network

struct StreamingScreen: View {

    @ObservedObject private var viewModel: DisplayStreamViewModel

    @State private var volume = 0.5
    @State private var showToolbar = false
    @State private var showSettings = false
    @State private var showSimulcastView = false
    @State private var showStats = false

    @Environment(\.dismiss) var dismiss

    init(dataStore: RTSDataStore) {
        self.viewModel = DisplayStreamViewModel(dataStore: dataStore)
    }

    var body: some View {
        BackgroundContainerView {
            ZStack {
                let screenRect = UIScreen.main.bounds
                let (videoFrameWidth, videoFrameHeight) = viewModel.calculateVideoViewWidthHeight(screenWidth: Float(screenRect.size.width), screenHeight: Float(screenRect.size.height))
                VideoRendererView(uiView: viewModel.streamingView)
                    .frame(width: videoFrameWidth, height: videoFrameHeight)

                VStack {}
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                    .opacity(viewModel.isStreamActive ? (showToolbar ? 0.5: 0.0) : 0.8)

#if os(tvOS)
                if viewModel.isLiveIndicatorEnabled {
                    VStack {
                        HStack {
                            Text(text: viewModel.isStreamActive ? "stream.live.label" : "stream.offline.label",
                                 fontAsset: .avenirNextBold(
                                    size: FontSize.caption2,
                                    style: .caption2
                                 )
                            ).padding(.leading, 20)
                                .padding(.trailing, 20)
                                .padding(.top, 6)
                                .padding(.bottom, 6)
                                .background(viewModel.isStreamActive ? Color(uiColor: UIColor.Feedback.error500) : Color(uiColor: UIColor.Neutral.neutral400))
                                .cornerRadius(Layout.cornerRadius6x)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }.frame(maxHeight: .infinity, alignment: .top)
                        .padding(.leading, 56)
                        .padding(.top, 37)
                }
#endif

                if viewModel.isStreamActive {
                    if showToolbar {
                        VStack {
                            HStack {
                                IconButton(
                                    text: "stream.settings.button",
                                    name: .settings
                                ) {
                                    withAnimation {
                                        showSettings = !showSettings
                                    }
                                }
                                Spacer().frame(width: Layout.spacing1x)
                            }.frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .padding()
                        .transition(.move(edge: .bottom))
                    } else {
#if os(tvOS)
                        AnyGestureRecognizer(triggered: $showToolbar)
#endif
                    }
                }

                if showSettings {
                    SettingsView(
                        disableLayers: viewModel.layersDisabled,
                        activeStreamTypes: viewModel.activeStreamTypes,
                        selectedLayer: viewModel.selectedLayer,
                        showSimulcastView: $showSimulcastView,
                        statsView: $showStats,
                        showLiveIndicator: $viewModel.isLiveIndicatorEnabled,
                        dataStore: viewModel.dataStore
                    )
                    .transition(.move(edge: .trailing))
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
            .onDisappear {
                Task {
                    await viewModel.stopSubscribe()
                }
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = viewModel.isStreamActive
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
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

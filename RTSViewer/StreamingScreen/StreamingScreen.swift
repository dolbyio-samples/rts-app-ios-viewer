//
//  StreamingScreen.swift
//  RTSViewer
//

import DolbyIOUIKit
import SwiftUI
import RTSComponentKit
import Network

struct StreamingScreen: View {

    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    @EnvironmentObject private var dataStore: RTSDataStore
    @EnvironmentObject private var persistentSettings: PersistentSettings

    @State private var volume = 0.5
    @State private var showToolbar = false
    @State private var showSettings = false
    @State private var showSimulcastView = false
    @State private var layersDisabled = true
    @State private var showStats = false
    @State private var isNetworkConnected: Bool = false
    @State private var selectedLayer: StreamType = .auto
    @State private var activeStreamType = [StreamType]()

    @Environment(\.dismiss) var dismiss

    var body: some View {
        BackgroundContainerView {
            ZStack {
                VideoRendererView(uiView: dataStore.subscriptionView())
#if os(iOS)
                    .frame(width: CGFloat(dataStore.statisticsData?.video?.frameWidth ?? 1280), height: CGFloat(dataStore.statisticsData?.video?.frameHeight ?? 720))
#endif
                VStack {}
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                    .opacity(isStreamActive ? (showToolbar ? 0.5: 0.0) : 0.8)

#if os(tvOS)
                if persistentSettings.liveIndicatorEnable {
                    VStack {
                        HStack {
                            Text(text: isStreamActive ? "stream.live.label" : "stream.offline.label",
                                 fontAsset: .avenirNextBold(
                                    size: FontSize.caption2,
                                    style: .caption2
                                 )
                            ).padding(.leading, 20)
                                .padding(.trailing, 20)
                                .padding(.top, 6)
                                .padding(.bottom, 6)
                                .background(isStreamActive ? Color(uiColor: UIColor.Feedback.error500) : Color(uiColor: UIColor.Neutral.neutral400))
                                .cornerRadius(Layout.cornerRadius6x)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }.frame(maxHeight: .infinity, alignment: .top)
                        .padding(.leading, 56)
                        .padding(.top, 37)
                }
#endif

                if isStreamActive {
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
                    SettingsView(settingsView: $showSettings, showSimulcastView: $showSimulcastView, disableLayers: $layersDisabled, liveIndicator: $persistentSettings.liveIndicatorEnable, statsView: $showStats, activeStreamType: $activeStreamType, selectedLayer: $selectedLayer, layerHandler: setLayer).transition(.move(edge: .trailing))
                }

                if !isStreamActive {
                    if isNetworkConnected {
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
                    StatisticsView(statsView: $showStats, stats: $dataStore.statisticsData)
                }
            }
            .task {
                let monitor = RTSComponentKit.NetworkMonitor.shared
                monitor.startMonitoring { path in
                    isNetworkConnected = path.status == .satisfied
                }
            }
            .edgesIgnoringSafeArea(.all)
            .onReceive(dataStore.$subscribeState) { subscribeState in
                Task {
                    UIApplication.shared.isIdleTimerDisabled = isStreamActive
                    switch subscribeState {
                    case .connected:
                        _ = await dataStore.startSubscribe()
                    case .streamInactive:
                        selectedLayer = StreamType.auto
                        _ = await dataStore.stopSubscribe()
                    case .disconnected:
                        layersDisabled = true
                    default:
                        // No-op
                        break
                    }
                }
            }
            .onReceive(dataStore.$layerActiveMap) { layers in
                Task {
                    activeStreamType = dataStore.activeStreamType
                    layersDisabled = layers.map { $0.count < 2 || $0.count > 3} ?? true

                    if !layersDisabled && selectedLayer != dataStore.activeLayer {
                        selectedLayer = dataStore.activeLayer

                        setLayer(streamType: selectedLayer)
                    }
                }
            }
            .onReceive(timer) { _ in
                Task {
                    switch dataStore.subscribeState {
                    case .error, .disconnected:
                        _ = await dataStore.connect()
                    default:
                        // No-op
                        break
                    }
                }
            }
            .onDisappear {
                Task {
                    _ = await dataStore.stopSubscribe()
                    timer.upstream.connect().cancel()
                }
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = isStreamActive
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

    private var isStreamActive: Bool {
        return dataStore.subscribeState == .streamActive
    }

    private func setLayer(streamType: StreamType) {
        dataStore.selectLayer(streamType: streamType)
    }

    private func hideToolbar() {
        withAnimation {
            showToolbar = false
        }
    }
}

private struct SettingsView: View {
    @Binding var settingsView: Bool
    @Binding var showSimulcastView: Bool
    @Binding var disableLayers: Bool
    @Binding var liveIndicator: Bool
    @Binding var statsView: Bool
    @Binding var activeStreamType: [StreamType]
    @Binding var selectedLayer: StreamType
    var layerHandler: (StreamType) -> Void

    var body: some View {
        ZStack {
            if !showSimulcastView {
                VStack {
                    VStack {
                        List {
                            Text(text: "stream.settings.label",
                                 mode: .secondary,
                                 fontAsset: .avenirNextBold(
                                    size: FontSize.title2,
                                    style: .title2
                                 )
                            ).foregroundColor(.white)

                            // TODO use DolbyIOUIKit.Button
                            Button(action: {
                                showSimulcastView = true
                            }, label: {
                                HStack {
                                    IconView(name: .simulcast, tintColor: Color(uiColor: UIColor.Neutral.neutral300))
                                    Text("stream.simulcast.label")
                                    Spacer()
                                    Text(selectedLayer.rawValue.capitalized)
                                    IconView(name: .textLink, tintColor: Color(uiColor: UIColor.Neutral.neutral300))
                                }
                            })
                            .padding(.leading, 28)
                            .padding(.trailing, 28)
                            .padding(.top, 18)
                            .padding(.bottom, 18)
                            .overlay(
                                RoundedRectangle(cornerRadius: Layout.cornerRadius14x)
                                    .stroke(.white, lineWidth: 1)
                            )
                            .disabled(disableLayers)

                            Toggle(isOn: $statsView, label: {
                                HStack {
                                    IconView(name: .info, tintColor: Color(uiColor: UIColor.Neutral.neutral300))
                                    Text("stream.media-stats.label")
                                }
                            })
                            .padding(.leading, 28)
                            .padding(.trailing, 28)
                            .overlay(
                                RoundedRectangle(cornerRadius: Layout.cornerRadius14x)
                                    .stroke(.white, lineWidth: 1)
                            )

                            Toggle(isOn: $liveIndicator, label: {
                                HStack {
                                    IconView(name: .liveStream, tintColor: Color(uiColor: UIColor.Neutral.neutral300))
                                    Text("stream.live-indicator.label")
                                }
                            })
                            .padding(.leading, 28)
                            .padding(.trailing, 28)
                            .overlay(RoundedRectangle(cornerRadius: Layout.cornerRadius14x)
                                .stroke(.white, lineWidth: 1)
                            )
                        }.background(Color(uiColor: UIColor.Neutral.neutral800))
                            .padding()

                    }.padding()
                        .frame(maxWidth: 700, maxHeight: .infinity, alignment: .bottom)
                }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }

            if showSimulcastView {
                SimulcastView(activeStreamType: $activeStreamType, selectedLayer: $selectedLayer, layerHandler: layerHandler).transition(.move(edge: .trailing))
            }
        }
    }
}

private struct SimulcastView: View {
    @Binding var activeStreamType: [StreamType]
    @Binding var selectedLayer: StreamType
    var layerHandler: (StreamType) -> Void

    var body: some View {
        VStack {
            VStack {
                VStack {
                    List {
                        Text(text: "stream.simulcast.label",
                             mode: .secondary,
                             fontAsset: .avenirNextBold(
                                size: FontSize.title2,
                                style: .title2
                             )
                        ).foregroundColor(.white)

                        ForEach(activeStreamType, id: \.self) { item in
                            // TODO use DolbyIOUIKit.Button
                            Button(action: {
                                selectedLayer = item
                                layerHandler(selectedLayer)
                            }, label: {
                                HStack {
                                    Text(item.rawValue.capitalized)
                                    Spacer()
                                    if item == selectedLayer {IconView(name: .checkmark, tintColor: Color(uiColor: UIColor.Neutral.neutral300))}
                                }
                            })
                            .padding(.leading, 28)
                            .padding(.trailing, 28)
                            .padding(.top, 18)
                            .padding(.bottom, 18)
                            .overlay(
                                RoundedRectangle(cornerRadius: Layout.cornerRadius14x)
                                    .stroke(.white, lineWidth: 1)
                            )
                        }
                    }.background(Color(uiColor: UIColor.Neutral.neutral800))
                        .padding()
                }
            }.padding()
                .frame(maxWidth: 700, maxHeight: .infinity, alignment: .bottom)
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
    }
}

#if DEBUG
struct StreamingScreen_Previews: PreviewProvider {
    static var previews: some View {
        StreamingScreen()
            .environmentObject(RTSDataStore())
            .environmentObject(PersistentSettings())
    }
}
#endif

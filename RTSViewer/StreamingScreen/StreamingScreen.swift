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
    @State private var volume = 0.5
    @State private var showSettings = false
    @State private var layersDisabled = true
    @State private var showLive = false
    @State private var showStats = false
    @State private var isNetworkConnected: Bool = false
    @State private var selectedLayer: StreamType = .auto

    var body: some View {
        BackgroundContainerView {
            ZStack {
                VideoRendererView(uiView: dataStore.subscriptionView())

                VStack {}
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                    .opacity(isStreamActive ? 0.0 : 0.8)

                if showLive {
                    VStack {
                        Spacer().frame(height: Layout.spacing1x)
                        HStack {
                            Text(text: "stream.live.label", fontAsset: .avenirNextDemiBold(
                                size: FontSize.callout,
                                style: .callout
                            )
                            ).padding()
                                .background(.red)
                            Spacer().frame(width: Layout.spacing1x)
                        }.frame(maxWidth: .infinity, alignment: .trailing)
                    }.frame(maxHeight: .infinity, alignment: .top)
                }

                if showSettings {
                    SettingsView(settingsView: $showSettings, disableLayers: $layersDisabled, liveIndicator: $showLive, statsView: $showStats, selectedLayer: $selectedLayer, layerHandler: setLayer)
                }

                if isStreamActive {
                    VStack {
                        HStack {
                            IconButton(name: .settings, tintColor: .white) {
                                showSettings = !showSettings
                            }
                            Spacer().frame(width: Layout.spacing1x)
                        }.frame(maxWidth: .infinity, alignment: .trailing)
                    }.frame(maxHeight: .infinity, alignment: .bottom)
                }

                if !isStreamActive {
                    if isNetworkConnected {
                        VStack {
                            Text(
                                text: "stream.offline.title.label",
                                fontAsset: .avenirNextDemiBold(
                                    size: FontSize.callout,
                                    style: .callout
                                )
                            )
                            Text(
                                text: "stream.offline.subtitle.label",
                                fontAsset: .avenirNextRegular(
                                    size: FontSize.title3,
                                    style: .title3
                                )
                            )
                        }
                    } else {
                        Text(
                            text: "stream.network.disconnected.label",
                            fontAsset: .avenirNextDemiBold(
                                size: FontSize.callout,
                                style: .callout
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
                    switch subscribeState {
                    case .connected, .streamInactive:
                        _ = await dataStore.startSubscribe()
                    default:
                        // No-op
                        break
                    }
                }
            }
            .onReceive(dataStore.$layerActiveMap) { layers in
                layersDisabled = layers.map { $0.count < 2 || $0.count > 3} ?? true
            }
            .onReceive(timer) { _ in
                Task {
                    switch dataStore.subscribeState {
                    case .error:
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
    }

    private var isStreamActive: Bool {
        return dataStore.subscribeState == .streamActive
    }

    private func setLayer(streamType: StreamType) {
        dataStore.selectLayer(streamType: streamType)
    }
}

private struct SettingsView: View {
    @Binding var settingsView: Bool
    @Binding var disableLayers: Bool
    @Binding var liveIndicator: Bool
    @Binding var statsView: Bool
    @Binding var selectedLayer: StreamType
    var layerHandler: (StreamType) -> Void

    var body: some View {
        VStack {
            VStack {
                VStack {
                    List {
                        HStack {
                            IconButton(name: .close, tintColor: .white) {
                                settingsView = false
                            }
                            Spacer().frame(width: Layout.spacing1x)
                        }.frame(maxWidth: .infinity, alignment: .trailing)

                            Picker("stream.simulcast.label", selection: $selectedLayer) {
                                ForEach(StreamType.allCases, id: \.self) { item in
                                    Text(item.rawValue.capitalized)
                                }
                            }.pickerStyle(.inline)
                                .onChange(of: selectedLayer) { layer in
                                    layerHandler(layer)
                                }
                                .disabled(disableLayers)

                        Toggle("stream.media-stats.label", isOn: $statsView)
                        Toggle("stream.live-indicator.label", isOn: $liveIndicator)
                    }.background(Color(uiColor: UIColor.Neutral.neutral800))

                    VStack {}.frame(height: 50)
                }.cornerRadius(Layout.cornerRadius6x)
            }.padding()
                .frame(maxWidth: 600, maxHeight: .infinity, alignment: .bottom)
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
    }
}

struct StreamingScreen_Previews: PreviewProvider {
    static var previews: some View {
        StreamingScreen()
            .environmentObject(RTSDataStore())
    }
}

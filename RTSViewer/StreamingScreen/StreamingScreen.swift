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

    @Environment(\.dismiss) var dismiss

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

                if isStreamActive {
                    VStack {
                        HStack {
                            IconButton(name: .settings, tintColor: .white) {
                                withAnimation {
                                    showSettings = !showSettings
                                }
                            }
                            Spacer().frame(width: Layout.spacing1x)
                        }.frame(maxWidth: .infinity, alignment: .trailing)
                    }.frame(maxHeight: .infinity, alignment: .bottom)
                        .padding()
                }

                if showSettings {
                    SettingsView(settingsView: $showSettings, disableLayers: $layersDisabled, liveIndicator: $showLive, statsView: $showStats, selectedLayer: $selectedLayer, layerHandler: setLayer).transition(.move(edge: .trailing))
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
        }.onExitCommand {
            if showStats {
                showStats = false
            } else if showSettings {
                showSettings = false
            } else {
                dismiss()
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
                        Text(text: "stream.settings.label",
                             mode: .secondary,
                             fontAsset: .avenirNextBold(
                                size: FontSize.title2,
                                style: .title2
                             )
                        ).foregroundColor(.white)

                        Picker("stream.simulcast.label", selection: $selectedLayer) {
                            ForEach(StreamType.allCases, id: \.self) { item in
                                Text(item.rawValue.capitalized)
                            }
                        }
                        .pickerStyle(.inline)
                        .onChange(of: selectedLayer) { layer in
                            layerHandler(layer)
                        }
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
                }
            }.padding()
                .frame(maxWidth: 700, maxHeight: .infinity, alignment: .bottom)
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
    }
}

struct StreamingScreen_Previews: PreviewProvider {
    static var previews: some View {
        StreamingScreen()
            .environmentObject(RTSDataStore())
    }
}

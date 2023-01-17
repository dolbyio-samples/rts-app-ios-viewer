//
//  StreamingScreen.swift
//  RTSViewer
//

import DolbyIOUIKit
import SwiftUI
import RTSComponentKit

enum StreamType: String, CaseIterable, Identifiable {
    case auto, high, medium, low
    var id: Self { self }
}

struct StreamingScreen: View {

    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    @EnvironmentObject private var dataStore: RTSDataStore
    @State private var volume = 0.5
    @State private var showSettings = false
    @State private var showLive = false
    @State private var showStats = false

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
                                size: FontSize.largeTitle,
                                style: .largeTitle
                            )
                            ).padding()
                                .background(.red)
                            Spacer().frame(width: Layout.spacing1x)
                        }.frame(maxWidth: .infinity, alignment: .trailing)
                    }.frame(maxHeight: .infinity, alignment: .top)
                }

                if showSettings {
                    SettingsView(settingsView: $showSettings, liveIndicator: $showLive, statsView: $showStats)
                }

                VStack {
                    HStack {
                        IconButton(name: .settings, tintColor: .white) {
                            showSettings = !showSettings
                        }
                        Spacer().frame(width: Layout.spacing1x)
                    }.frame(maxWidth: .infinity, alignment: .trailing)
                }.frame(maxHeight: .infinity, alignment: .bottom)

                if !isStreamActive {
                    VStack {
                        Text(
                            text: "stream.offline.title.label",
                            fontAsset: .avenirNextDemiBold(
                                size: FontSize.largeTitle,
                                style: .largeTitle
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
                }
            }
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
}

private struct SettingsView: View {
    @Binding var settingsView: Bool
    @Binding var liveIndicator: Bool
    @Binding var statsView: Bool

    @State private var selectedFlavor: StreamType = .auto

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

                        if #available(tvOS 16.0, *) {
                            Picker("stream.simulcast.label", selection: $selectedFlavor) {
                                ForEach(StreamType.allCases, id: \.self) { item in
                                    Text(item.rawValue.capitalized)
                                }
                            }.pickerStyle(.navigationLink)
                        } else {
                            Picker("stream.simulcast.label", selection: $selectedFlavor) {
                                ForEach(StreamType.allCases, id: \.self) { item in
                                    Text(item.rawValue.capitalized)
                                }
                            }.pickerStyle(.inline)
                        }

                        Toggle("stream.media-stats.label", isOn: $statsView)
                        Toggle("stream.live-indicator.label", isOn: $liveIndicator)
                    }.background(Color(uiColor: UIColor.Neutral.neutral800))

                    VStack {}.frame(height: 50)
                }.cornerRadius(Layout.cornerRadius6x)
            }.padding()
                .frame(maxWidth: 600, maxHeight: 450, alignment: .bottom)
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
    }
}

struct StreamingScreen_Previews: PreviewProvider {
    static var previews: some View {
        StreamingScreen()
            .environmentObject(RTSDataStore())
    }
}

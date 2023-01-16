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
    @State private var mediaStats = false
    @State private var liveIndicator = false
    @State private var selectedFlavor: StreamType = .auto
    @State private var showSettings = false

    var body: some View {
        BackgroundContainerView {
            ZStack {
                VideoRendererView(uiView: dataStore.subscriptionView())

                VStack {}
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                    .opacity(isStreamActive ? 0.0 : 0.8)

                if(showSettings) {
                    VStack {
                        VStack {
                            Spacer().frame(width: Layout.spacing1x)
                            List {
                                
                                if #available(tvOS 16.0, *) {
                                    Picker("Simulcast", selection: $selectedFlavor) {
                                        ForEach(StreamType.allCases, id: \.self) { item in // 4
                                            Text(item.rawValue.capitalized) // 5
                                        }
                                    }.pickerStyle(.navigationLink)
                                } else {
                                    // Fallback on earlier versions
                                }
                                
                                
                                Toggle("Media stats", isOn: $mediaStats)
                                Toggle("Live indicator", isOn:$liveIndicator)
                            }
                        }.frame(maxWidth: 800, maxHeight: 600, alignment: .bottom)
                    }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                }
                
                VStack {
                    HStack {
                        IconButton(name: .settings, tintColor: .white, focusedBackgroundColor: .white) {
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

struct StreamingScreen_Previews: PreviewProvider {
    static var previews: some View {
        StreamingScreen()
            .environmentObject(RTSDataStore())
    }
}

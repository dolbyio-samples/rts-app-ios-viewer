//
//  SettingsView.swift
//

import DolbyIOUIKit
import RTSComponentKit
import SwiftUI

struct SettingsView: View {
    let disableLayers: Bool
    let activeStreamTypes: [StreamType]
    let selectedLayer: StreamType

    @Binding var showSimulcastView: Bool
    @Binding var statsView: Bool
    @Binding var showLiveIndicator: Bool

    private let dataStore: RTSDataStore

    init(
        disableLayers: Bool,
        activeStreamTypes: [StreamType],
        selectedLayer: StreamType,
        showSimulcastView: Binding<Bool>,
        statsView: Binding<Bool>,
        showLiveIndicator: Binding<Bool>,
        dataStore: RTSDataStore
    ) {
        self.disableLayers = disableLayers
        self.activeStreamTypes = activeStreamTypes
        self.selectedLayer = selectedLayer
        self.dataStore = dataStore
        _showSimulcastView = showSimulcastView
        _statsView = statsView
        _showLiveIndicator = showLiveIndicator
    }

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

                            Toggle(isOn: $showLiveIndicator, label: {
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
                        }
                        .background(Color(uiColor: UIColor.Neutral.neutral800))
                        .padding()

                    }
                    .padding()
                    .frame(maxWidth: 700, maxHeight: .infinity, alignment: .bottom)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }

            if showSimulcastView {
                SimulcastView(
                    activeStreamTypes: activeStreamTypes,
                    selectedLayer: selectedLayer,
                    dataStore: dataStore
                )
                .transition(.move(edge: .trailing))
            }
        }
    }
}

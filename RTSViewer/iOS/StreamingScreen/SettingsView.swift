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

    @Binding var showSettings: Bool

    private let dataStore: RTSDataStore

    init(
        disableLayers: Bool,
        activeStreamTypes: [StreamType],
        selectedLayer: StreamType,
        showSimulcastView: Binding<Bool>,
        statsView: Binding<Bool>,
        showLiveIndicator: Binding<Bool>,
        showSettings: Binding<Bool>,
        dataStore: RTSDataStore
    ) {
        self.disableLayers = disableLayers
        self.activeStreamTypes = activeStreamTypes
        self.selectedLayer = selectedLayer
        self.dataStore = dataStore
        _showSettings = showSettings
    }

    var body: some View {
        ZStack {
            VStack {
                VStack {
                    ZStack {
                        Text(text: "stream.settings.label",
                             mode: .secondary,
                             fontAsset: .avenirNextBold(
                                size: FontSize.title2,
                                style: .title2
                             )
                        )
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                        HStack {
                            HStack {
                                IconButton(
                                    name: .close
                                ) {
                                    withAnimation {
                                        showSettings = false
                                    }
                                }
                                .tint(.white)
                                .background(Color(uiColor: UIColor.Neutral.neutral400))
                                .clipShape(Circle())
                                Spacer().frame(width: Layout.spacing1x)
                            }.frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                    Divider()
                    SimulcastView(
                        activeStreamTypes: activeStreamTypes,
                        selectedLayer: selectedLayer,
                        dataStore: dataStore
                    )
                    .background(Color(uiColor: UIColor.Neutral.neutral800))
                    .cornerRadius(Layout.cornerRadius14x)
                    .padding()
                }
            }.frame(maxWidth: 400, maxHeight: 400, alignment: .center)
        }
        .background(.black)
        .cornerRadius(Layout.cornerRadius14x)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .transition(.move(edge: .bottom))
    }
}

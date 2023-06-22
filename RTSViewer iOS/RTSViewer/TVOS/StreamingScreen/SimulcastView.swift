//
//  SimulcastView.swift
//

import DolbyIOUIKit
import RTSComponentKit
import SwiftUI

struct SimulcastView: View {
    let activeStreamTypes: [StreamType]
    let selectedLayer: StreamType

    @StateObject private var viewModel: SimulcastViewModel

    init(activeStreamTypes: [StreamType], selectedLayer: StreamType, dataStore: RTSDataStore) {
        self.activeStreamTypes = activeStreamTypes
        self.selectedLayer = selectedLayer
        _viewModel = StateObject(wrappedValue: SimulcastViewModel(dataStore: dataStore))
    }

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

                        ForEach(activeStreamTypes, id: \.self) { item in
                            Button(action: {
                                viewModel.setLayer(streamType: item)
                            }, label: {
                                HStack {
                                    Text(item.rawValue.capitalized)
                                    Spacer()
                                    if item == selectedLayer {
                                        IconView(
                                            name: .checkmark,
                                            tintColor: Color(uiColor: UIColor.Neutral.neutral300)
                                        )
                                    }
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
                    }
                    .background(Color(uiColor: UIColor.Neutral.neutral800))
                    .padding()
                }
            }.padding()
                .frame(maxWidth: 700, maxHeight: .infinity, alignment: .bottom)
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
    }
}

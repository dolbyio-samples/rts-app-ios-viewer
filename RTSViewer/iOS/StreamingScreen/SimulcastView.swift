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
        List {
            Section {
                ForEach(activeStreamTypes, id: \.self) { item in
                    // TODO use DolbyIOUIKit.Button
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
                }
            } header: {
                Text("video quality")
            }
        }
        .onAppear {
            UITableView.appearance().backgroundColor = .clear
        }
    }
}

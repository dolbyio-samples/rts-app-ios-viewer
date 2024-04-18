//
//  SimulcastView.swift
//

import DolbyIOUIKit
import RTSComponentKit
import SwiftUI

struct SimulcastView: View {
    let videoQualityList: [VideoQuality]
    let selectedVideoQuality: VideoQuality

    private let viewModel: SimulcastViewModel

    init(videoQualityList: [VideoQuality], selectedVideoQuality: VideoQuality, dataStore: RTSDataStore) {
        self.videoQualityList = videoQualityList
        self.selectedVideoQuality = selectedVideoQuality
        viewModel = SimulcastViewModel(dataStore: dataStore)
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

                        ForEach(videoQualityList, id: \.self) { item in
                            Button(action: {
                                Task {
                                    await viewModel.setLayer(quality: item)
                                }
                            }, label: {
                                HStack {
                                    Text(item.rawValue.capitalized)
                                    Spacer()
                                    if item == selectedVideoQuality {
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

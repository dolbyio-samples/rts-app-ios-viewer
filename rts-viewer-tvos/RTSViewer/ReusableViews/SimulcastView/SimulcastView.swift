//
//  SimulcastView.swift
//

import DolbyIOUIKit
import RTSCore
import SwiftUI

struct SimulcastView: View {
    private enum FocusableField: Hashable {
        case qualityLayerId(id: String)
    }

    private let theme = ThemeManager.shared.theme
    private let viewModel: SimulcastViewModel
    private let onSelectVideoQuality: (VideoQuality) -> Void
    @FocusState private var focusedVideoQuality: FocusableField?

    init(
        source: StreamSource,
        videoQualityList: [VideoQuality],
        selectedVideoQuality: VideoQuality,
        onSelectVideoQuality: @escaping (VideoQuality) -> Void
    ) {
        viewModel = SimulcastViewModel(source: source, videoQualityList: videoQualityList, selectedVideoQuality: selectedVideoQuality)
        self.onSelectVideoQuality = onSelectVideoQuality
    }

    var body: some View {
        VStack(alignment: .center) {
            title

            ForEach(viewModel.videoQualityList, id: \.self.encodingId) {
                videoQualityButton(for: $0)
                    .focused($focusedVideoQuality, equals: .qualityLayerId(id: $0.encodingId))
            }

            Spacer()
        }
        .focusSection()
        .padding(Layout.spacing3x)
        .frame(maxWidth: UIScreen.main.bounds.size.width / 3)
        .background(Color(uiColor: UIColor.Neutral.neutral800))
        .onAppear {
            focusedVideoQuality = .qualityLayerId(id: viewModel.videoQualityList[0].encodingId)
        }
    }

    private var title: some View {
        HStack {
            Text(
                text: "stream.simulcast.label",
                mode: .secondary,
                fontAsset: .avenirNextBold(
                    size: FontSize.title3,
                    style: .title3
                )
            )
            .foregroundColor(.white)

            Spacer()
        }
    }

    private func videoQualityButton(for videoQuality: VideoQuality) -> some View {
        Button(action: {
            onSelectVideoQuality(videoQuality)
        }, label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(videoQuality.displayText)
                        .font(theme[.avenirNextDemiBold(size: FontSize.body, style: .body)])
                    if let targetInformation = videoQuality.targetInformation {
                        Text(targetInformation)
                            .font(theme[.avenirNextRegular(size: FontSize.caption2, style: .caption2)])
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer()
                if videoQuality.encodingId == viewModel.selectedVideoQuality.encodingId {
                    IconView(
                        name: .checkmark,
                        tintColor: Color(uiColor: UIColor.Neutral.neutral300)
                    )
                }
            }
            .frame(height: Layout.spacing10x)
        })
    }
}

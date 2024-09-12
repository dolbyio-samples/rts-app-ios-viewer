//
//  ChannelDetailInputView.swift
//  Interactive Player
//

import DolbyIOUIKit
import MillicastSDK
import RTSCore
import SwiftUI

struct ChannelDetailInputView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var viewModel: ChannelDetailInputViewModel
    @State var additionalInputCount: Int = 0

    init(viewModel: ChannelDetailInputViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 0) {
                if horizontalSizeClass == .regular {
                    Spacer()
                        .frame(height: Layout.spacing5x)
                } else {
                    Spacer()
                        .frame(height: Layout.spacing3x)
                }

                Text(
                    "stream-detail-input.title.label",
                    style: .labelMedium,
                    font: .custom("AvenirNext-DemiBold", size: FontSize.title1, relativeTo: .title)
                )

                Spacer()
                    .frame(height: Layout.spacing3x)

                Text(
                    "channel-detail-input.start-a-channel.label",
                    style: .labelMedium,
                    font: .custom("AvenirNext-DemiBold", size: FontSize.title2, relativeTo: .title)
                )

                Spacer()
                    .frame(height: Layout.spacing1x)

                Text(
                    "channel-detail-input.subtitle.label",
                    font: .custom("AvenirNext-Regular", size: FontSize.subhead, relativeTo: .subheadline)
                )
                .multilineTextAlignment(.center)

                Spacer()
                    .frame(height: Layout.spacing3x)

                VStack(alignment: .trailing, spacing: Layout.spacing1x) {
                    channelInput(labelName: "channel-detail-input.channel-1.label",
                                 streamName: $viewModel.streamName1,
                                 accountID: $viewModel.accountID1,
                                 showPlus: false)

                    channelInput(labelName: "channel-detail-input.channel-2.label",
                                 streamName: $viewModel.streamName2,
                                 accountID: $viewModel.accountID2,
                                 showPlus: additionalInputCount == 0)

                    if additionalInputCount > 0 {
                        channelInput(labelName: "channel-detail-input.channel-3.label",
                                     streamName: $viewModel.streamName3,
                                     accountID: $viewModel.accountID3,
                                     showPlus: additionalInputCount == 1)
                    }

                    if additionalInputCount > 1 {
                        channelInput(labelName: "channel-detail-input.channel-4.label",
                                     streamName: $viewModel.streamName4,
                                     accountID: $viewModel.accountID4,
                                     showPlus: false)
                        .padding(.bottom, Layout.spacing2x)
                    }

                    Button(
                        action: {
                            viewModel.playButtonPressed()
                        },
                        text: "stream-detail-input.play.button"
                    )
                }
                .frame(maxWidth: 400)
            }
            .padding([.leading, .trailing], Layout.spacing3x)
        }
    }

    @ViewBuilder
    private func channelInput(
        labelName: LocalizedStringKey,
        streamName: Binding<String>,
        accountID: Binding<String>,
        showPlus: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: Layout.spacing2x) {
            Text(
                labelName,
                font: .custom("AvenirNext-Bold", size: FontSize.subhead, relativeTo: .subheadline)
            )
            .multilineTextAlignment(.leading)
            .padding(.top, Layout.spacing3x)

            DolbyIOUIKit.TextField(text: streamName, placeholderText: "stream-detail-streamname-placeholder-label")
                .accessibilityIdentifier("InputScreen.StreamNameInput")
                .font(.avenirNextRegular(withStyle: .caption, size: FontSize.caption1))

            DolbyIOUIKit.TextField(text: accountID, placeholderText: "stream-detail-accountid-placeholder-label")
                .accessibilityIdentifier("InputScreen.AccountIDInput")
                .font(.avenirNextRegular(withStyle: .caption, size: FontSize.caption1))
        }

        if showPlus {
            VStack(alignment: .trailing) {
                IconButton(
                    iconAsset: .plus
                ) {
                    additionalInputCount += 1
                }
            }
        }
    }
}

#Preview {
    ChannelDetailInputView(viewModel: ChannelDetailInputViewModel(channels: .constant(nil), showChannelView: .constant(false), streamDataManager: StreamDataManager.shared, dateProvider: DefaultDateProvider()))
}

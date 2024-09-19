//
//  ChannelDetailInputBox.swift
//

import DolbyIOUIKit
import RTSCore
import SwiftUI

struct ChannelDetailInputBox: View {
    @ObservedObject var viewModel: ChannelDetailInputViewModel

    init(viewModel: ChannelDetailInputViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: Layout.spacing2x) {
                Text(
                    text: "stream-detail-input.header.label",
                    fontAsset: .avenirNextDemiBold(
                        size: FontSize.body,
                        style: .body
                    )
                )

                VStack(spacing: Layout.spacing1x) {
                    Text(
                        text: "channel-detail-input.start-a-channel.label",
                        mode: .secondary,
                        fontAsset: .avenirNextDemiBold(
                            size: FontSize.title3,
                            style: .title3
                        )
                    )

                    Text(
                        text: "channel-detail-input.subtitle.label",
                        fontAsset: .avenirNextRegular(
                            size: FontSize.caption2,
                            style: .caption2
                        )
                    )
                }
                ScrollView {
                    channelInput(placeholderStream: "channel-detail-input.streamName.placeholder1.label",
                                 placeholderAccount: "channel-detail-input.accountId.placeholder1.label",
                                 channelName: "channel-detail-input.channel-1.label",
                                 streamName: $viewModel.streamName1,
                                 accountID: $viewModel.accountID1)

                    channelInput(placeholderStream: "channel-detail-input.streamName.placeholder2.label",
                                 placeholderAccount: "channel-detail-input.accountId.placeholder2.label",
                                 channelName: "channel-detail-input.channel-2.label",
                                 streamName: $viewModel.streamName2,
                                 accountID: $viewModel.accountID2)

                    channelInput(placeholderStream: "channel-detail-input.streamName.placeholder3.label",
                                 placeholderAccount: "channel-detail-input.accountId.placeholder3.label",
                                 channelName: "channel-detail-input.channel-3.label",
                                 streamName: $viewModel.streamName3,
                                 accountID: $viewModel.accountID3)

                    channelInput(placeholderStream: "channel-detail-input.streamName.placeholder4.label",
                                 placeholderAccount: "channel-detail-input.accountId.placeholder4.label",
                                 channelName: "channel-detail-input.channel-4.label",
                                 streamName: $viewModel.streamName4,
                                 accountID: $viewModel.accountID4)
                }

                Button(
                    action: {
                        viewModel.playButtonPressed()
                    },
                    text: "stream-detail-input.play.button"
                )

                Spacer()
                    .frame(height: Layout.spacing8x)
            }
            .padding(.all, Layout.spacing5x)
            .background(Color(uiColor: UIColor.Background.black))
            .cornerRadius(Layout.cornerRadius6x)
            .frame(width: proxy.size.width / 3)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
        private func channelInput(
            placeholderStream: LocalizedStringKey,
            placeholderAccount: LocalizedStringKey,
            channelName: LocalizedStringKey,
            streamName: Binding<String>,
            accountID: Binding<String>
        ) -> some View {
            VStack(alignment: .leading, spacing: Layout.spacing2x) {
                Text(text: channelName,
                     font: .custom("AvenirNext-Bold", size: FontSize.caption1, relativeTo: .caption)
                )
                .multilineTextAlignment(.leading)
                .padding(.top, Layout.spacing3x)

                TextField(placeholderStream, text: streamName)
                    .font(.avenirNextRegular(withStyle: .caption, size: FontSize.caption1))

                TextField(placeholderAccount, text: accountID)
                    .font(.avenirNextRegular(withStyle: .caption, size: FontSize.caption1))

            }
        }
}

// #Preview {
//    ChannelDetailInputBox(viewModel: ChannelDetailInputViewModel(isShowingChannelView: .constant(true), onPlayTapped: {}))
// }

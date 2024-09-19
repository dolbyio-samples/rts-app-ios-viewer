//
//  StreamDetailInputBox.swift
//

import DolbyIOUIKit
import RTSCore
import SwiftUI

struct StreamDetailInputBox: View {
    @ObservedObject var viewModel: StreamDetailInputViewModel

    init(viewModel: StreamDetailInputViewModel) {
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
                        text: "stream-detail-input.title.label",
                        mode: .secondary,
                        fontAsset: .avenirNextDemiBold(
                            size: FontSize.title3,
                            style: .title3
                        )
                    )

                    Text(
                        text: "stream-detail-input.subtitle.label",
                        fontAsset: .avenirNextRegular(
                            size: FontSize.caption2,
                            style: .caption2
                        )
                    )
                }

                VStack(spacing: Layout.spacing3x) {
                    TextField("stream-detail-input.streamName.placeholder.label", text: $viewModel.streamName)
                        .font(.avenirNextRegular(withStyle: .caption, size: FontSize.caption1))

                    TextField("stream-detail-input.accountId.placeholder.label", text: $viewModel.accountID)
                        .font(.avenirNextRegular(withStyle: .caption, size: FontSize.caption1))

                    if viewModel.hasSavedStreams {
                        Button(
                            action: {
                                viewModel.isShowingRecentStreams = true
                            },
                            text: "stream-detail-input.recent-streams.button",
                            mode: .secondary
                        )
                    }

                    Button(
                        action: {
                            viewModel.playStream()
                        },
                        text: "stream-detail-input.play.button"
                    )

                    if viewModel.hasSavedStreams {
                        HStack {
                            LinkButton(
                                action: {
                                    viewModel.isShowingClearStreamsAlert = true
                                },
                                text: "stream-detail-input.clear-stream-history.button",
                                fontAsset: .avenirNextBold(size: FontSize.caption2, style: .caption2)
                            )

                            Spacer()
                        }
                    }
                }
                Spacer()
                    .frame(height: Layout.spacing8x)
            }
            .sheet(isPresented: $viewModel.isShowingRecentStreams) {
                RecentStreamsView(
                    streamName: $viewModel.streamName,
                    accountID: $viewModel.accountID,
                    isShowingRecentStreams: $viewModel.isShowingRecentStreams
                ) {
                    viewModel.playStream()
                }
            }
            .padding(.all, Layout.spacing5x)
            .background(Color(uiColor: UIColor.Background.black))
            .cornerRadius(Layout.cornerRadius6x)
            .frame(width: proxy.size.width / 3)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

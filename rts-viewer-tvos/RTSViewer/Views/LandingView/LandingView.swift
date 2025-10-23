//
//  LandingView.swift
//

import DolbyIOUIKit
import RTSCore
import SwiftUI

struct LandingView: View {
    @ObservedObject private var viewModel = LandingViewModel()

    var body: some View {
        BackgroundContainerView {
            ZStack {
                /*
                 NavigationLink - Adds an unnecessary padding across its containing view -
                 so Øscreen navigations are not visually rendered - but only used for programmatic navigation
                 - in this case - controlled by the Binded `Bool` value.
                 */

                NavigationLink(destination: StreamingView(streamName: viewModel.streamName, accountID: viewModel.accountID, playoutDelay: createPlayoutDelay()), isActive: $viewModel.isShowingStreamingView) {
                    EmptyView()
                }
                .hidden()

                let channelViewModel = ChannelViewModel(unsourcedChannels: $viewModel.unsourcedChannel) {
                    viewModel.isShowingChannelView = false
                }
                NavigationLink(destination: ChannelView(viewModel: channelViewModel), isActive: $viewModel.isShowingChannelView) {
                    EmptyView()
                }
                .hidden()

                VStack {
                    Spacer()
                    streamInputBox

                    Spacer()
                    HStack(spacing: Layout.spacing6x) {
                        DolbyIOUIKit.Text(
                            text: "\(viewModel.appVersion)",
                            font: .avenirNextRegular(
                                withStyle: .caption,
                                size: FontSize.caption1
                            )
                        )

                        DolbyIOUIKit.Text(
                            text: "\(viewModel.sdkVersion)",
                            font: .avenirNextRegular(
                                withStyle: .caption,
                                size: FontSize.caption1
                            )
                        )
                    }

                    FooterView(text: "stream-detail-input.footnote.label")
                        .padding(.bottom, Layout.spacing3x)
                }
            }
        }
        .navigationHeaderView()
        .navigationBarHidden(true)
        .alert("stream-detail-input.credentials-error.label", isPresented: $viewModel.isShowingErrorAlert) {}
        .alert("stream-detail-input.clear-streams.label", isPresented: $viewModel.isShowingClearStreamsAlert, actions: {
            Button(
                "stream-detail-input.clear-streams.alert.clear.button",
                role: .destructive,
                action: {
                    viewModel.clearAllStreams()
                }
            )
            Button(
                "stream-detail-input.clear-streams.alert.cancel.button",
                role: .cancel,
                action: {}
            )
        })
    }

    @ViewBuilder var streamInputBox: some View {
        let streamDetailInputViewModel = StreamDetailInputViewModel(streamName: $viewModel.streamName,
                                                                    accountID: $viewModel.accountID,
                                                                    playoutDelayMin: $viewModel.playoutDelayMin,
                                                                    playoutDelayMax: $viewModel.playoutDelayMax,
                                                                    channels: $viewModel.unsourcedChannel,
                                                                    isShowingStreamingView: $viewModel.isShowingStreamingView,
                                                                    isShowingChannelView: $viewModel.isShowingChannelView,
                                                                    isShowingRecentStreams: $viewModel.isShowingRecentStreams)
        StreamDetailInputBox(viewModel: streamDetailInputViewModel)
    }

    private func createPlayoutDelay() -> PlayoutDelay {
        var playoutDelay = PlayoutDelay()
        if let min = viewModel.playoutDelayMin,
              let max = viewModel.playoutDelayMax,
              min <= max {
            playoutDelay = PlayoutDelay(min: min, max: max)
        }
        return playoutDelay
    }
}

struct StreamDetailInputView_Previews: PreviewProvider {
    static var previews: some View {
        LandingView()
    }
}

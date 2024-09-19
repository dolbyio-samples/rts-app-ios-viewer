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

                NavigationLink(destination: StreamingView(streamName: viewModel.streamName, accountID: viewModel.accountID), isActive: $viewModel.isShowingStreamingView) {
                    EmptyView()
                }
                .hidden()

                let channelViewModel = ChannelViewModel(channels: $viewModel.channels) {
                    viewModel.isShowingChannelView = false
                }
                NavigationLink(destination: ChannelView(viewModel: channelViewModel), isActive: $viewModel.isShowingChannelView) {
                    EmptyView()
                }
                .hidden()

                VStack {
                    Spacer()
                    TabView {
                        let streamDetailInputViewModel = StreamDetailInputViewModel(streamName: $viewModel.streamName,
                                                                                    accountID: $viewModel.accountID,
                                                                                    isShowingStreamingView: $viewModel.isShowingStreamingView,
                                                                                    isShowingRecentStreams: $viewModel.isShowingRecentStreams)
                        StreamDetailInputBox(viewModel: streamDetailInputViewModel)
                            .tabItem { Label("SingleView", systemImage: "tv") }

                        let channelDetailInputViewModel = ChannelDetailInputViewModel(channels: $viewModel.channels,
                                                                                      isShowingChannelView: $viewModel.isShowingChannelView)
                        ChannelDetailInputBox(viewModel: channelDetailInputViewModel)
                            .tabItem { Label("MultiChannel", systemImage: "tv") }
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
}

struct StreamDetailInputView_Previews: PreviewProvider {
    static var previews: some View {
        LandingView()
    }
}

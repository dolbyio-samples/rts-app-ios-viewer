//
//  StreamDetailInputView.swift
//

import DolbyIOUIKit
import RTSCore
import SwiftUI

struct StreamDetailInputView: View {
    @ObservedObject private var viewModel = StreamDetailInputViewModel()

    var body: some View {
        BackgroundContainerView {
            ZStack {
                /*
                 NavigationLink - Adds an unnecessary padding across its containing view -
                 so screen navigations are not visually rendered - but only used for programmatic navigation
                 - in this case - controlled by the Binded `Bool` value.
                 */

                NavigationLink(destination: StreamingView(streamName: viewModel.streamName, accountID: viewModel.accountID), isActive: $viewModel.isShowingStreamingView) {
                    EmptyView()
                }
                .hidden()

                // TODO play channelview
//                NavigationLink(destination: ChannelView(streamName: viewModel.streamName, accountID: viewModel.accountID), isActive: $viewModel.isShowingChannelView) {
//                    EmptyView()
//                }
//                .hidden()

                VStack {
                    Spacer()
                    TabView {
                        StreamDetailInputBox(viewModel: viewModel)
                            .tabItem { Label("SingleView", systemImage: "tv") }

                        // TODO: onplaytapped
                        let channelDetailInputViewModel = ChannelDetailInputViewModel(isShowingChannelView: $viewModel.isShowingChannelView, onPlayTapped: {})
                        ChannelDetailInputBox(viewModel: channelDetailInputViewModel)
                            .tabItem { Label("MultiChannel", systemImage: "tv") }
                    }

                    FooterView(text: "stream-detail-input.footnote.label")
                        .padding(.bottom, Layout.spacing3x)
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
        StreamDetailInputView()
    }
}

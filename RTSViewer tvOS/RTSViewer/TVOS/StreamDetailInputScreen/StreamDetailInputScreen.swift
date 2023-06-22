//
//  StreamDetailInputScreen.swift
//

import DolbyIOUIKit
import SwiftUI
import RTSComponentKit

struct StreamDetailInputScreen: View {

    @State private var streamName: String = ""
    @State private var accountID: String = ""
    @State private var isShowingStreamingView: Bool = false
    @State private var isShowingRecentStreams: Bool = false

    @StateObject private var viewModel: StreamDetailInputViewModel = .init()

    var body: some View {
        BackgroundContainerView {
            ZStack {

                /*
                 NavigationLink - Adds an unnecessary padding across its containing view -
                 so screen navigations are not visually rendered - but only used for programmatic navigation
                 - in this case - controlled by the Binded `Bool` value.
                 */

                NavigationLink(destination: LazyNavigationDestinationView(StreamingScreen(dataStore: viewModel.dataStore)), isActive: $isShowingStreamingView) {
                    EmptyView()
                }
                .hidden()

                VStack {
                    StreamDetailInputBox(
                        viewModel: viewModel,
                        streamName: $streamName,
                        accountID: $accountID,
                        isShowingStreamingView: $isShowingStreamingView,
                        isShowingRecentStreams: $isShowingRecentStreams
                    )

                    Spacer()
                    FooterView(text: "stream-detail-input.footnote.label")
                        .padding(.bottom, Layout.spacing3x)
                }
                .sheet(isPresented: $isShowingRecentStreams) {
                    RecentStreamsScreen(
                        streamName: $streamName,
                        accountID: $accountID,
                        isShowingRecentStreams: $isShowingRecentStreams) {
                            Task.delayed(byTimeInterval: 0.60) {
                                let success = await viewModel.connect(streamName: streamName, accountID: accountID)
                                await MainActor.run {
                                    isShowingStreamingView = success
                                    viewModel.saveStream(streamName: streamName, accountID: accountID)
                                }
                            }
                        }
                }
            }
        }
        .navigationHeaderView()
        .navigationBarHidden(true)
    }
}

private struct StreamDetailInputBox: View {
    @Binding private var streamName: String
    @Binding private var accountID: String
    @Binding private var isShowingStreamingView: Bool
    @Binding private var isShowingRecentStreams: Bool

    @State private var showingAlert = false
    @State private var showingClearStreamsAlert = false

    @ObservedObject private var viewModel: StreamDetailInputViewModel

    init(
        viewModel: StreamDetailInputViewModel,
        streamName: Binding<String>,
        accountID: Binding<String>,
        isShowingStreamingView: Binding<Bool>,
        isShowingRecentStreams: Binding<Bool>
    ) {
        self.viewModel = viewModel
        self._streamName = streamName
        self._accountID = accountID
        self._isShowingStreamingView = isShowingStreamingView
        self._isShowingRecentStreams = isShowingRecentStreams
    }

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: Layout.spacing6x) {
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
                            size: FontSize.title2,
                            style: .title2
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

                    TextField("stream-detail-input.streamName.placeholder.label", text: $streamName)
                        .onReceive(streamName.publisher) { _ in
                            streamName = String(streamName.prefix(64))
                        }
                        .font(.avenirNextRegular(withStyle: .caption, size: FontSize.caption1))

                    TextField("stream-detail-input.accountId.placeholder.label", text: $accountID)
                        .onReceive(accountID.publisher) { _ in
                            accountID = String(accountID.prefix(64))
                        }
                        .font(.avenirNextRegular(withStyle: .caption, size: FontSize.caption1))

                    if viewModel.hasSavedStreams {
                        DolbyIOUIKit.Button(
                            action: {
                                isShowingRecentStreams = true
                            },
                            text: "stream-detail-input.recent-streams.button",
                            mode: .secondary
                        )
                    }

                    SubscribeButton(
                        text: "stream-detail-input.play.button",
                        streamName: streamName,
                        accountID: accountID,
                        dataStore: viewModel.dataStore) { success in
                            showingAlert = !success
                            isShowingStreamingView = success
                            if success {
                                // A delay is added before saving the stream.
                                // Workaround - the `clear stream` and `saved streams` buttons appear before the screen transition animation completes.
                                Task.delayed(byTimeInterval: 0.50) {
                                    await viewModel.saveStream(streamName: streamName, accountID: accountID)
                                }
                            }
                        }

                    if viewModel.hasSavedStreams {
                        HStack {
                            LinkButton(
                                action: {
                                    showingClearStreamsAlert = true
                                },
                                text: "stream-detail-input.clear-stream-history.button",
                                fontAsset: .avenirNextBold(size: FontSize.caption2, style: .caption2)
                            )

                            Spacer()
                        }
                    }
                }
                .alert("stream-detail-input.credentials-error.label", isPresented: $showingAlert) { }
                .alert("stream-detail-input.clear-streams.label", isPresented: $showingClearStreamsAlert, actions: {
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

                Spacer()
                    .frame(height: Layout.spacing8x)
            }
            .padding(.all, Layout.spacing5x)
#if os(tvOS)
            .background(Color(uiColor: UIColor.Background.black))
            .cornerRadius(Layout.cornerRadius6x)
            .frame(width: proxy.size.width / 3)
#endif
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct StreamDetailInputScreen_Previews: PreviewProvider {
    static var previews: some View {
        StreamDetailInputScreen()
    }
}

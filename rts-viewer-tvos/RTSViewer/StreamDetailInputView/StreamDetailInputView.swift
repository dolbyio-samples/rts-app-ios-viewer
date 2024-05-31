//
//  StreamDetailInputView.swift
//

import DolbyIOUIKit
import SwiftUI
import RTSComponentKit

struct StreamDetailInputView: View {

    @State private var streamName: String = ""
    @State private var accountID: String = ""

    @State private var isShowingStreamingView: Bool = false
    @State private var isShowingRecentStreams: Bool = false
    @State private var isShowingErrorAlert = false
    @State private var isShowingClearStreamsAlert = false

    @StateObject private var viewModel: StreamDetailInputViewModel = .init()

    var body: some View {
        BackgroundContainerView {
            ZStack {

                /*
                 NavigationLink - Adds an unnecessary padding across its containing view -
                 so screen navigations are not visually rendered - but only used for programmatic navigation
                 - in this case - controlled by the Binded `Bool` value.
                 */

                NavigationLink(destination: StreamingView(subscriptionManager: viewModel.subscriptionManager), isActive: $isShowingStreamingView) {
                    EmptyView()
                }
                .hidden()

                VStack {
                    StreamDetailInputBox(
                        streamName: $streamName,
                        accountID: $accountID,
                        isShowingStreamingView: $isShowingStreamingView,
                        isShowingRecentStreams: $isShowingRecentStreams,
                        isShowingClearStreamsAlert: $isShowingClearStreamsAlert,
                        hasSavedStreams: viewModel.hasSavedStreams,
                        onPlayTapped: {
                            playStream()
                        }
                    )

                    Spacer()
                    FooterView(text: "stream-detail-input.footnote.label")
                        .padding(.bottom, Layout.spacing3x)
                }
                .sheet(isPresented: $isShowingRecentStreams) {
                    RecentStreamsView(
                        streamName: $streamName,
                        accountID: $accountID,
                        isShowingRecentStreams: $isShowingRecentStreams
                    ) {
                        playStream()
                    }
                }
            }
        }
        .navigationHeaderView()
        .navigationBarHidden(true)
        .alert("stream-detail-input.credentials-error.label", isPresented: $isShowingErrorAlert) { }
        .alert("stream-detail-input.clear-streams.label", isPresented: $isShowingClearStreamsAlert, actions: {
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

    private func playStream() {
        Task {
            guard viewModel.checkIfCredentialsAreValid(streamName: streamName, accountID: accountID) else {
                isShowingErrorAlert = true
                return
            }

            isShowingStreamingView = true
            viewModel.saveStream(streamName: streamName, accountID: accountID)
            try await viewModel.connect(streamName: streamName, accountID: accountID)
        }
    }
}

private struct StreamDetailInputBox: View {
    @Binding private var streamName: String
    @Binding private var accountID: String
    @Binding private var isShowingStreamingView: Bool
    @Binding private var isShowingRecentStreams: Bool
    @Binding private var isShowingClearStreamsAlert: Bool
    private let hasSavedStreams: Bool
    private let onPlayTapped: () -> Void

    init(
        streamName: Binding<String>,
        accountID: Binding<String>,
        isShowingStreamingView: Binding<Bool>,
        isShowingRecentStreams: Binding<Bool>,
        isShowingClearStreamsAlert: Binding<Bool>,
        hasSavedStreams: Bool,
        onPlayTapped: @escaping () -> Void
    ) {
        _streamName = streamName
        _accountID = accountID
        _isShowingStreamingView = isShowingStreamingView
        _isShowingRecentStreams = isShowingRecentStreams
        _isShowingClearStreamsAlert = isShowingClearStreamsAlert
        self.hasSavedStreams = hasSavedStreams
        self.onPlayTapped = onPlayTapped
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

                    if hasSavedStreams {
                        DolbyIOUIKit.Button(
                            action: {
                                isShowingRecentStreams = true
                            },
                            text: "stream-detail-input.recent-streams.button",
                            mode: .secondary
                        )
                    }

                    Button(
                        action: {
                            onPlayTapped()
                        },
                        text: "stream-detail-input.play.button"
                    )

                    if hasSavedStreams {
                        HStack {
                            LinkButton(
                                action: {
                                    isShowingClearStreamsAlert = true
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
            .padding(.all, Layout.spacing5x)
            .background(Color(uiColor: UIColor.Background.black))
            .cornerRadius(Layout.cornerRadius6x)
            .frame(width: proxy.size.width / 3)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct StreamDetailInputView_Previews: PreviewProvider {
    static var previews: some View {
        StreamDetailInputView()
    }
}

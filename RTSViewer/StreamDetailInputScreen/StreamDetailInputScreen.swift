//
//  StreamDetailInputScreen.swift
//  RTSViewer
//

import DolbyIOUIKit
import SwiftUI
import RTSComponentKit

struct StreamDetailInputScreen: View {

    @State private var streamName: String = ""
    @State private var accountID: String = ""
    @State private var isShowingStreamingView: Bool = false

    var body: some View {
        NavigationView {
            BackgroundContainerView {
                ZStack {

                    /*
                     NavigationLink - Adds an unnecessary padding across its containing view -
                     so screen navigations are not visually rendered - but only used for programmatic navigation
                     - in this case - controlled by the Binded `Bool` value.
                     */

                    NavigationLink(destination: StreamingScreen(), isActive: $isShowingStreamingView) {
                        EmptyView()
                    }
                    .hidden()

                    VStack {
                        StreamDetailInputBox(streamName: $streamName, accountID: $accountID, isShowingStreamingView: $isShowingStreamingView)

                        Spacer()
                        Text(
                            text: "stream-detail-input.footnote.label",
                            fontAsset: .avenirNextRegular(
                                size: FontSize.footnote,
                                style: .footnote
                            )
                        )
                        .padding(.bottom, Layout.spacing3x)
                    }
                }
            }
            .navigationHeaderView()
            .navigationBarHidden(true)
        }
    }
}

private struct StreamDetailInputBox: View {
    @Binding private var streamName: String
    @Binding private var accountID: String
    @Binding private var isShowingStreamingView: Bool

    @EnvironmentObject private var dataStore: RTSDataStore

    @State private var showingAlert = false

    init(streamName: Binding<String>, accountID: Binding<String>, isShowingStreamingView: Binding<Bool>) {
        self._streamName = streamName
        self._accountID = accountID
        self._isShowingStreamingView = isShowingStreamingView
    }

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: Layout.spacing3x) {
                Text(
                    text: "stream-detail-input.header.label",
                    fontAsset: .avenirNextDemiBold(
                        size: FontSize.title3,
                        style: .title3
                    )
                )

                VStack(spacing: Layout.spacing1x) {
                    Text(
                        text: "stream-detail-input.title.label",
                        mode: .secondary,
                        fontAsset: .avenirNextDemiBold(
                            size: FontSize.largeTitle,
                            style: .largeTitle
                        )
                    )

                    Text(
                        text: "stream-detail-input.subtitle.label",
                        fontAsset: .avenirNextRegular(
                            size: FontSize.headline,
                            style: .headline
                        )
                    )
                }

                VStack(spacing: Layout.spacing3x) {

                    TextField("stream-detail-input.streamName.placeholder.label", text: $streamName)
                        .onReceive(streamName.publisher) { _ in
                            streamName = String(streamName.prefix(64))
                        }
                        .font(.avenirNextRegular(withStyle: .body, size: FontSize.headline))

                    TextField("stream-detail-input.accountId.placeholder.label", text: $accountID)
                        .onReceive(accountID.publisher) { _ in
                            accountID = String(accountID.prefix(64))
                        }
                        .font(.avenirNextRegular(withStyle: .body, size: FontSize.headline))

                    RTSComponentKit.SubscribeButton(
                        text: "stream-detail-input.play.button",
                        streamName: streamName,
                        accountID: accountID,
                        dataStore: dataStore) { success in
                            showingAlert = !success
                            isShowingStreamingView = success
                        }
                }
                .alert("stream-detail-input.credentials-error.labal", isPresented: $showingAlert) { }

                Spacer()
                    .frame(height: Layout.spacing12x)
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
            .environmentObject(RTSDataStore())
    }
}

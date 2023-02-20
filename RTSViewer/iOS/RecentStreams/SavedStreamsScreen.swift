//
//  SavedStreamsScreen.swift
//

import DolbyIOUIKit
import RTSComponentKit
import SwiftUI

struct SavedStreamsScreen: View {
    @ObservedObject var viewModel: RecentStreamsViewModel

    private let theme = ThemeManager.shared.theme
    @State private var isShowingStreamInputView: Bool = false
    @State private var isShowingFullStreamHistoryView: Bool = false
    @State private var isShowingStreamingView: Bool = false

    @State private var isShowingClearStreamsAlert = false

    @Environment(\.presentationMode) private var presentation
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        ZStack {
            NavigationLink(
                destination: LazyNavigationDestinationView(StreamDetailInputScreen()),
                isActive: $isShowingStreamInputView) {
                    EmptyView()
                }
                .hidden()

            NavigationLink(
                destination: LazyNavigationDestinationView(StreamingScreen(dataStore: viewModel.dataStore)),
                isActive: $isShowingStreamingView) {
                    EmptyView()
                }
                .hidden()

            if viewModel.streamDetails.isEmpty {
                VStack(spacing: Layout.spacing1x) {
                    Text(
                        text: "saved-streams.empty-streams.title.label",
                        fontAsset: .avenirNextDemiBold(
                            size: FontSize.title2,
                            style: .title2
                        )
                    )
                    .multilineTextAlignment(.center)

                    Text(
                        text: "saved-streams.empty-streams.subtitle.label",
                        mode: .secondary,
                        fontAsset: .avenirNextRegular(
                            size: FontSize.subhead,
                            style: .subheadline
                        )
                    )
                    .multilineTextAlignment(.center)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        IconButton(name: .chevronLeft, tintColor: .white, action: {
                            presentation.wrappedValue.dismiss()
                        })
                    }
                }
                .edgesIgnoringSafeArea(.all)
            } else {
                ScrollView {
                    Spacer()
                        .frame(height: Layout.spacing4x)

                    if let lastPlayedStream = viewModel.lastPlayedStream {
                        VStack(alignment: .leading) {
                            DolbyIOUIKit.Text(
                                text: "saved-streams.section.last-played.label",
                                font: theme[
                                    .avenirNextMedium(
                                        size: FontSize.footnote,
                                        style: .footnote
                                    )
                                ]
                            )

                            RecentStreamCell(streamName: lastPlayedStream.streamName, accountID: lastPlayedStream.accountID) {
                                Task {
                                    let success = await viewModel.connect(streamName: lastPlayedStream.streamName, accountID: lastPlayedStream.accountID)
                                    await MainActor.run {
                                        isShowingStreamingView = success
                                        viewModel.saveStream(streamName: lastPlayedStream.streamName, accountID: lastPlayedStream.accountID)
                                    }
                                }
                            }
                        }
                    }

                    Spacer()
                        .frame(height: Layout.spacing3x)

                    VStack(alignment: .leading) {
                        DolbyIOUIKit.Text(
                            text: "saved-streams.section.all-streams.label",
                            font: theme[
                                .avenirNextMedium(
                                    size: FontSize.footnote,
                                    style: .footnote
                                )
                            ]
                        )

                        VStack {
                            ForEach(viewModel.topStreamDetails) { streamDetail in
                                if let streamName = streamDetail.streamName, let accountID = streamDetail.accountID {
                                    RecentStreamCell(streamName: streamName, accountID: accountID) {
                                        Task {
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
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        IconButton(name: .chevronLeft, tintColor: .white, action: {
                            presentation.wrappedValue.dismiss()
                        })
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        IconButton(name: .delete, tintColor: .white, action: {
                            isShowingClearStreamsAlert = true
                        })
                    }
                }
            }
        }
        .layoutPriority(1)
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("saved-streams.title.label")
        .padding([.leading, .trailing], horizontalSizeClass == .regular ? Layout.spacing5x : Layout.spacing3x)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: UIColor.Neutral.neutral900))
        .alert("saved-streams.clear-streams.label", isPresented: $isShowingClearStreamsAlert, actions: {
            Button(
                "saved-streams.clear-streams.alert.clear.button",
                role: .destructive,
                action: {
                    viewModel.clearAllStreams()
                }
            )
            Button(
                "saved-streams.clear-streams.alert.cancel.button",
                role: .cancel,
                action: {}
            )
        })
    }
}

struct SavedStreamsScreen_Previews: PreviewProvider {
    static var previews: some View {
        SavedStreamsScreen(viewModel: .init())
    }
}

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
    @State private var showActionSheet = false
    @State private var selectedStreamDetail: StreamDetail?

    @Environment(\.presentationMode) private var presentation
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var connectionManager: ConnectionManager

    init(viewModel: RecentStreamsViewModel) {
        self.viewModel = viewModel
        connectionManager = ConnectionManager()
    }

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
                .onDisappear {
                    connectionManager.stopBrowsing()
                }

            if viewModel.streamDetails.isEmpty {
                emptyListBody
            } else {
                listBody
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

    private var emptyListBody: some View {
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
    }

    private var listBody: some View {
        List {
            Spacer()
                .frame(height: Layout.spacing2x)
                .listRowBackground(Color.clear)

            if let lastPlayedStream = viewModel.lastPlayedStream {
                DolbyIOUIKit.Text(
                    text: "saved-streams.section.last-played.label",
                    font: theme[
                        .avenirNextMedium(
                            size: FontSize.footnote,
                            style: .footnote
                        )
                    ]
                )
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .frame(height: Layout.spacing4x)

                ForEach([lastPlayedStream]) { streamDetail in
                    if let streamName = streamDetail.streamName, let accountID = streamDetail.accountID {
                        RecentStreamCell(moreAction: true, streamName: streamName, accountID: accountID) {
                            selectedStreamDetail = streamDetail
                            showActionSheet = true
                        }
                    }
                }
                .onDelete(perform: viewModel.delete(at:))
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }

            Spacer()
                .frame(height: Layout.spacing2x)
                .listRowBackground(Color.clear)

            DolbyIOUIKit.Text(
                text: "saved-streams.section.all-streams.label",
                font: theme[
                    .avenirNextMedium(
                        size: FontSize.footnote,
                        style: .footnote
                    )
                ]
            )
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .frame(height: Layout.spacing4x)

            ForEach(viewModel.streamDetails) { streamDetail in
                if let streamName = streamDetail.streamName, let accountID = streamDetail.accountID {
                    RecentStreamCell(moreAction: true, streamName: streamName, accountID: accountID) {
                        selectedStreamDetail = streamDetail
                        showActionSheet = true
                    }

                    Spacer()
                        .frame(height: Layout.spacing1x)
                }
            }
            .onDelete(perform: viewModel.delete(at:))
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
        }
        .environment(\.defaultMinListRowHeight, 0)
        .listStyle(.plain)
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
        .frame(maxWidth: 600)
        .actionSheet(isPresented: $showActionSheet) {
            ActionSheet(title: Text("What do you want to do with this stream?"),
                        message: nil, buttons: [
                            .default(Text("Play"), action: {
                                guard let name = selectedStreamDetail?.streamName,
                                      let id = selectedStreamDetail?.accountID else { return }
                                Task {
                                    let success = await viewModel.connect(streamName: name, accountID: id)
                                    await MainActor.run {
                                        isShowingStreamingView = success
                                        viewModel.saveStream(streamName: name, accountID: id)
                                    }
                                }
                                selectedStreamDetail = nil
                            }),
                            .default(Text("Share"), action: {
                                Task {
                                    connectionManager.startBrowsing()
                                }
                            }),
                            .cancel()
                        ])
        }
        .onReceive(connectionManager.$clients) { clients in
            guard let streamDetail = selectedStreamDetail else { return }
            clients.forEach { client in
                connectionManager.invitePeer(client, to: streamDetail)
            }
            selectedStreamDetail = nil
        }
    }
}

struct SavedStreamsScreen_Previews: PreviewProvider {
    static var previews: some View {
        SavedStreamsScreen(viewModel: .init())
    }
}

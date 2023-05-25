//
//  SavedStreamsScreen.swift
//

import DolbyIOUIKit
import DolbyIORTSCore
import DolbyIORTSUIKit
import SwiftUI

struct SavedStreamsScreen: View {

    @ObservedObject var viewModel: RecentStreamsViewModel
    @ObservedObject private var globalSettingsViewModel: StreamSettingsViewModel

    private let theme = ThemeManager.shared.theme
    @State private var isShowingStreamInputView: Bool = false
    @State private var isShowingFullStreamHistoryView: Bool = false
    @State private var isShowingStreamingView: Bool = false

    @State private var isShowingClearStreamsAlert = false

    @Environment(\.presentationMode) private var presentation
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(_ viewModel: RecentStreamsViewModel,
         globalSettingsViewModel: StreamSettingsViewModel) {
        self.viewModel = viewModel
        self.globalSettingsViewModel = globalSettingsViewModel
    }

    var body: some View {
        ZStack {
            NavigationLink(
                destination: LazyNavigationDestinationView(StreamDetailInputScreen(globalSettingsViewModel)),
                isActive: $isShowingStreamInputView) {
                    EmptyView()
                }
                .hidden()

            NavigationLink(
                destination: LazyNavigationDestinationView(StreamingScreen()),
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
                            let streamName = streamDetail.streamName
                            let accountID = streamDetail.accountID
                            RecentStreamCell(streamName: streamName, accountID: accountID) {
                                Task {
                                    let success = await viewModel.connect(streamName: streamDetail.streamName, accountID: streamDetail.accountID)
                                    await MainActor.run {
                                        isShowingStreamingView = success
                                        viewModel.saveStream(streamName: streamDetail.streamName, accountID: streamDetail.accountID)
                                    }
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
                        let streamName = streamDetail.streamName
                        let accountID = streamDetail.accountID
                        RecentStreamCell(streamName: streamName, accountID: accountID) {
                            Task {
                                let success = await viewModel.connect(streamName: streamName, accountID: accountID)
                                await MainActor.run {
                                    isShowingStreamingView = success
                                    viewModel.saveStream(streamName: streamName, accountID: accountID)
                                }
                            }
                        }

                        Spacer()
                            .frame(height: Layout.spacing1x)
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
        SavedStreamsScreen(.init(), globalSettingsViewModel: .init(settings: StreamSettings()))
    }
}

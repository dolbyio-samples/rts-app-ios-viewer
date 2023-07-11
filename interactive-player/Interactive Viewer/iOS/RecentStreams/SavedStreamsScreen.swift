//
//  SavedStreamsScreen.swift
//

import DolbyIOUIKit
import DolbyIORTSUIKit
import SwiftUI

struct SavedStreamsScreen: View {
    @ObservedObject var viewModel: RecentStreamsViewModel

    @ObservedObject private var themeManager = ThemeManager.shared
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
                destination: LazyNavigationDestinationView(StreamingScreen(isShowingStreamView: $isShowingStreamingView)),
                isActive: $isShowingStreamingView) {
                    EmptyView()
                }
                .hidden()

            if viewModel.streamDetails.isEmpty {
                VStack(spacing: Layout.spacing1x) {
                    Text(
                        "saved-streams.empty-streams.title.label",
                        font: .custom("AvenirNext-DemiBold", size: FontSize.title2, relativeTo: .title2)
                    )
                    .multilineTextAlignment(.center)

                    Text(
                        "saved-streams.empty-streams.subtitle.label",
                        style: .labelMedium,
                        font: .custom("AvenirNext-Regular", size: FontSize.subhead, relativeTo: .subheadline)
                    )
                    .multilineTextAlignment(.center)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        IconButton(iconAsset: .chevronLeft, tintColor: .white, action: {
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
                            "saved-streams.section.last-played.label",
                            font: .custom("AvenirNext-Medium", size: FontSize.footnote, relativeTo: .footnote)
                        )
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .frame(height: Layout.spacing4x)

                        ForEach([lastPlayedStream]) { streamDetail in
                            let streamName = streamDetail.streamName
                            let accountID = streamDetail.accountID
                            let isDev = streamDetail.isDev == "true" ? true : false
                            let forcePlayoutDelay = streamDetail.forcePlayoutDelay == "true" ? true : false
                            let disableAudio = streamDetail.disableAudio == "true" ? true : false
                            let saveLogs = streamDetail.saveLogs == "true" ? true : false
                            RecentStreamCell(streamName: streamName, accountID: accountID, dev: isDev, forcePlayoutDelay: forcePlayoutDelay, disableAudio: disableAudio, saveLogs: saveLogs) {
                                Task {
                                    let success = await viewModel.connect(streamName: streamDetail.streamName, accountID: streamDetail.accountID, dev: isDev, forcePlayoutDelay: forcePlayoutDelay, disableAudio: disableAudio, saveLogs: saveLogs)
                                    await MainActor.run {
                                        isShowingStreamingView = success
                                        viewModel.saveStream(streamName: streamDetail.streamName, accountID: streamDetail.accountID, dev: isDev, forcePlayoutDelay: forcePlayoutDelay, disableAudio: disableAudio, saveLogs: saveLogs)
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
                        "saved-streams.section.all-streams.label",
                        font: .custom("AvenirNext-Medium", size: FontSize.footnote, relativeTo: .footnote)
                    )
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .frame(height: Layout.spacing4x)

                    ForEach(viewModel.streamDetails) { streamDetail in
                        let streamName = streamDetail.streamName
                        let accountID = streamDetail.accountID
                        let isDev = streamDetail.isDev == "true" ? true : false
                        let forcePlayoutDelay = streamDetail.forcePlayoutDelay == "true" ? true : false
                        let disableAudio = streamDetail.disableAudio == "true" ? true : false
                        let saveLogs = streamDetail.saveLogs == "true" ? true : false
                        RecentStreamCell(streamName: streamName, accountID: accountID, dev: isDev, forcePlayoutDelay: forcePlayoutDelay, disableAudio: disableAudio, saveLogs: saveLogs) {
                            Task {
                                let success = await viewModel.connect(streamName: streamName, accountID: accountID, dev: isDev, forcePlayoutDelay: forcePlayoutDelay, disableAudio: disableAudio, saveLogs: saveLogs)
                                await MainActor.run {
                                    isShowingStreamingView = success
                                    viewModel.saveStream(streamName: streamName, accountID: accountID, dev: isDev, forcePlayoutDelay: forcePlayoutDelay, disableAudio: disableAudio, saveLogs: saveLogs)
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
                        IconButton(iconAsset: .chevronLeft, tintColor: .white, action: {
                            presentation.wrappedValue.dismiss()
                        })
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        IconButton(iconAsset: .delete, tintColor: .white, action: {
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
        .background(Color(uiColor: themeManager.theme.neutral900))
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

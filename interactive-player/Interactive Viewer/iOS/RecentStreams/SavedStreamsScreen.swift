//
//  SavedStreamsScreen.swift
//

import DolbyIORTSCore
import DolbyIOUIKit
import DolbyIORTSUIKit
import SwiftUI

struct SavedStreamsScreen: View {
    @ObservedObject var viewModel: RecentStreamsViewModel

    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var isShowingStreamInputView: Bool = false
    @State private var isShowingFullStreamHistoryView: Bool = false
    @State private var isShowingClearStreamsAlert = false
    @State private var streamingScreenContext: StreamingScreen.Context?

    @Environment(\.presentationMode) private var presentation
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        ZStack {
            NavigationLink(
                destination: LazyNavigationDestinationView(
                    StreamDetailInputScreen(streamingScreenContext: $streamingScreenContext)
                ),
                isActive: $isShowingStreamInputView) {
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
                        .accessibilityIdentifier("SavedStreamsScreen.BackIconButton")
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
                        .listRowInsets(listRowEdgeInsets)
                        .listRowSeparator(.hidden)
                        .frame(height: Layout.spacing4x)

                        ForEach([lastPlayedStream]) { streamDetail in
                            RecentStreamCell(streamDetail: streamDetail) {
                                playStream(streamDetail: streamDetail)
                            }
                        }
                        .onDelete(perform: viewModel.delete)
                        .listRowBackground(Color.clear)
                        .listRowInsets(listRowEdgeInsets)
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
                    .listRowInsets(listRowEdgeInsets)
                    .listRowSeparator(.hidden)
                    .frame(height: Layout.spacing4x)

                    ForEach(viewModel.streamDetails) { streamDetail in
                        RecentStreamCell(streamDetail: streamDetail) {
                            playStream(streamDetail: streamDetail)
                        }

                        Spacer()
                            .frame(height: Layout.spacing1x)
                    }
                    .onDelete(perform: viewModel.delete(at:))
                    .listRowBackground(Color.clear)
                    .listRowInsets(listRowEdgeInsets)
                    .listRowSeparator(.hidden)
                }
                .environment(\.defaultMinListRowHeight, 0)
                .listStyle(.plain)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        IconButton(iconAsset: .chevronLeft, tintColor: .white, action: {
                            presentation.wrappedValue.dismiss()
                        })
                        .accessibilityIdentifier("SavedStreamsScreen.BackIconButton")
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        IconButton(iconAsset: .delete, tintColor: .white, action: {
                            isShowingClearStreamsAlert = true
                        })
                        .accessibilityIdentifier("SavedStreamsScreen.DeleteIconButton")
                    }
                }
                .frame(maxWidth: 600)
            }
        }
        .layoutPriority(1)
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("saved-streams.title.label")
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
            .accessibilityIdentifier("SavedStreamsScreen.ClearButton")
            Button(
                "saved-streams.clear-streams.alert.cancel.button",
                role: .cancel,
                action: {}
            )
            .accessibilityIdentifier("SavedStreamsScreen.CancelButton")
        })
        .fullScreenCover(item: $streamingScreenContext) { context in
            StreamingScreen(
                context: context,
                listViewPrimaryVideoQuality: .high
            ) {
                streamingScreenContext = nil
            }
        }
    }

    private func playStream(streamDetail: SavedStreamDetail) {
        let success = viewModel.connect(streamDetail: streamDetail, saveLogs: streamDetail.saveLogs)
        if success {
            streamingScreenContext = .init(
                streamName: streamDetail.streamName,
                accountID: streamDetail.accountID,
                listViewPrimaryVideoQuality: streamDetail.primaryVideoQuality
            )
        }
    }

    private var listRowEdgeInsets: EdgeInsets {
        let horizontalInset = horizontalSizeClass == .regular ? Layout.spacing5x : Layout.spacing3x
        return EdgeInsets(top: 0, leading: horizontalInset, bottom: 0, trailing: horizontalInset)
    }
}

struct SavedStreamsScreen_Previews: PreviewProvider {
    static var previews: some View {
        SavedStreamsScreen(viewModel: .init())
    }
}

//
//  RecentStreamsScreen.swift
//

import DolbyIOUIKit
import DolbyIORTSCore
import DolbyIORTSUIKit
import SwiftUI

struct RecentStreamsScreen: View {
    @StateObject private var viewModel: RecentStreamsViewModel = .init()

    @ObservedObject private var themeManager = ThemeManager.shared

    @State private var isShowingStreamInputView: Bool = false
    @State private var isShowingFullStreamHistoryView: Bool = false
    @State private var isShowingStreamingView: Bool = false

    @State private var isShowingSettingScreenView: Bool = false
    @State var isShowLabelOn: Bool = false

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        ZStack(alignment: Alignment(horizontal: .center, vertical: .top)) {
            NavigationLink(
                destination: LazyNavigationDestinationView(StreamDetailInputScreen()),
                isActive: $isShowingStreamInputView) {
                    EmptyView()
                }
                .hidden()

            NavigationLink(
                destination: LazyNavigationDestinationView(SavedStreamsScreen(viewModel: viewModel)),
                isActive: $isShowingFullStreamHistoryView) {
                    EmptyView()
                }
                .hidden()

            NavigationLink(
                destination: LazyNavigationDestinationView(StreamingScreen(isShowingStreamView: $isShowingStreamingView)),
                isActive: $isShowingStreamingView) {
                    EmptyView()
                }
                .hidden()

            NavigationLink(
                destination: LazyNavigationDestinationView(SettingsScreen()),
                isActive: $isShowingSettingScreenView) {
                    EmptyView()
                }
                .hidden()

            ScrollView {
                VStack(spacing: Layout.spacing3x) {
                    Spacer()
                        .frame(height: Layout.spacing3x)

                    VStack(spacing: Layout.spacing1x) {
                        Text(
                            "recent-streams.title.label",
                            font: .custom("AvenirNext-DemiBold", size: FontSize.largeTitle, relativeTo: .title)
                        )

                        Text(
                            "recent-streams.subtitle.label",
                            style: .bodyMedium,
                            font: .custom("AvenirNext-Regular", size: FontSize.subhead, relativeTo: .subheadline)
                        )
                        .multilineTextAlignment(.center)
                    }

                    VStack(spacing: Layout.spacing2x) {
                        HStack {
                            DolbyIOUIKit.Text(
                                "recent-streams.table-header-label",
                                font: .custom("AvenirNext-Medium", size: FontSize.footnote, relativeTo: .footnote)
                            )

                            Spacer()

                            LinkButton(
                                action: {
                                    isShowingFullStreamHistoryView = true
                                },
                                text: "recent-streams.table-header-button",
                                font: .custom("AvenirNext-Medium", size: FontSize.footnote, relativeTo: .footnote),
                                padding: Layout.spacing0x
                            )
                        }

                        VStack(spacing: Layout.spacing1x) {
                            ForEach(viewModel.topStreamDetails) { streamDetail in
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
                            }
                        }
                    }
                    .frame(maxWidth: 600)

                    Text(
                        "recent-streams.option-separator.label",
                        style: .bodyMedium,
                        font: .custom("AvenirNext-DemiBold", size: FontSize.caption2, relativeTo: .caption2)
                    )

                    Button(
                        action: {
                            isShowingStreamInputView = true
                        },
                        text: "recent-streams.play-new.button"
                    )
                    .frame(maxWidth: 400)
                }
            }
            .layoutPriority(1)
            .navigationBarTitleDisplayMode(.inline)
            .padding([.leading, .trailing], horizontalSizeClass == .regular ? Layout.spacing5x : Layout.spacing3x)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: themeManager.theme.neutral900))
            .toolbar {
                ToolbarItem(placement: .principal) {
                    IconView(iconAsset: .dolby_logo_dd, tintColor: .white)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    IconButton(iconAsset: .settings, action: {
                        isShowingSettingScreenView = true
                    })
                }

                ToolbarItem(placement: .bottomBar) {
                    FooterView(text: "recent-streams.footnote.label")
                }
            }
            .onAppear {
                viewModel.fetchAllStreams()
            }
        }
    }
}

#if DEBUG
struct RecentStreamsScreen_Previews: PreviewProvider {
    static var previews: some View {
        RecentStreamsScreen()
    }
}
#endif

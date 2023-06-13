//
//  RecentStreamsScreen.swift
//

import DolbyIOUIKit
import DolbyIORTSCore
import DolbyIORTSUIKit
import SwiftUI

struct RecentStreamsScreen: View {
    @StateObject private var viewModel: RecentStreamsViewModel = .init()

    private let theme = ThemeManager.shared.theme

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
                            text: "recent-streams.title.label",
                            fontAsset: .avenirNextDemiBold(
                                size: FontSize.largeTitle,
                                style: .largeTitle
                            )
                        )

                        Text(
                            text: "recent-streams.subtitle.label",
                            mode: .secondary,
                            fontAsset: .avenirNextRegular(
                                size: FontSize.subhead,
                                style: .subheadline
                            )
                        )
                        .multilineTextAlignment(.center)
                    }

                    VStack(spacing: Layout.spacing2x) {
                        HStack {
                            DolbyIOUIKit.Text(
                                text: "recent-streams.table-header-label",
                                font: theme[
                                    .avenirNextMedium(
                                        size: FontSize.footnote,
                                        style: .footnote
                                    )
                                ]
                            )

                            Spacer()

                            LinkButton(
                                action: {
                                    isShowingFullStreamHistoryView = true
                                },
                                text: "recent-streams.table-header-button",
                                font: theme[
                                    .avenirNextMedium(
                                        size: FontSize.footnote,
                                        style: .footnote
                                    )
                                ],
                                padding: Layout.spacing0x
                            )
                        }

                        VStack(spacing: Layout.spacing1x) {
                            ForEach(viewModel.topStreamDetails) { streamDetail in
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
                            }
                        }
                    }
                    .frame(maxWidth: 600)

                    Text(
                        text: "recent-streams.option-separator.label",
                        mode: .secondary,
                        fontAsset: .avenirNextDemiBold(
                            size: FontSize.caption2,
                            style: .caption2
                        )
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
            .background(Color(uiColor: UIColor.Neutral.neutral900))
            .toolbar {
                ToolbarItem(placement: .principal) {
                    IconView(name: .dolby_logo_dd, tintColor: .white)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    IconButton(name: .settings, action: {
                        SettingsManager.shared.setActiveSettings(for: .global)
                        isShowingSettingScreenView = true
                    }).scaleEffect(0.5, anchor: .trailing)
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

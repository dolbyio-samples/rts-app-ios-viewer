//
//  RecentStreamsScreen.swift
//

import DolbyIOUIKit
import DolbyIORTSCore
import SwiftUI

struct RecentStreamsScreen: View {
    @ObservedObject private var viewModel: RecentStreamsViewModel
    @ObservedObject private var themeManager = ThemeManager.shared

    @Binding private var isShowingStreamInputView: Bool
    @Binding private var isShowingFullStreamHistoryView: Bool
    @Binding private var isShowingSettingsView: Bool
    @Binding private var streamingScreenContext: StreamingView.Context?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(
        viewModel: RecentStreamsViewModel,
        isShowingStreamInputView: Binding<Bool>,
        isShowingFullStreamHistoryView: Binding<Bool>,
        isShowingSettingsView: Binding<Bool>,
        streamingScreenContext: Binding<StreamingView.Context?>
    ) {
        self.viewModel = viewModel
        _isShowingStreamInputView = isShowingStreamInputView
        _streamingScreenContext = streamingScreenContext
        _isShowingFullStreamHistoryView = isShowingFullStreamHistoryView
        _isShowingSettingsView = isShowingSettingsView
    }

    var body: some View {
        ZStack(alignment: Alignment(horizontal: .center, vertical: .top)) {
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
                                RecentStreamCell(streamDetail: streamDetail) {
                                    let success = viewModel.connect(streamDetail: streamDetail, saveLogs: streamDetail.saveLogs)
                                    if success {
                                        streamingScreenContext = .init(
                                            streamName: streamDetail.streamName,
                                            accountID: streamDetail.accountID,
                                            listViewPrimaryVideoQuality: streamDetail.primaryVideoQuality,
                                            subscriptionManager: viewModel.subscriptionManager
                                        )
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
                    .accessibilityIdentifier("RecentStreamsScreen.PlayNewButton")
                }
                .padding([.leading, .trailing], horizontalSizeClass == .regular ? Layout.spacing5x : Layout.spacing3x)
            }
            .layoutPriority(1)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: themeManager.theme.neutral900))
        }
        .onAppear {
            viewModel.fetchAllStreams()
        }
    }
}

#if DEBUG
struct RecentStreamsScreen_Previews: PreviewProvider {
    static var previews: some View {
        RecentStreamsScreen(
            viewModel: RecentStreamsViewModel(),
            isShowingStreamInputView: .constant(false),
            isShowingFullStreamHistoryView: .constant(false),
            isShowingSettingsView: .constant(false),
            streamingScreenContext: .constant(nil)
        )
    }
}
#endif

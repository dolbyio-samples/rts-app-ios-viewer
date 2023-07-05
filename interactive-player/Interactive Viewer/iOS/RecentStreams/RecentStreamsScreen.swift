//
//  RecentStreamsScreen.swift
//

import DolbyIOUIKit
import DolbyIORTSCore
import DolbyIORTSUIKit
import SwiftUI

struct RecentStreamsScreen: View {
    @ObservedObject private var viewModel: RecentStreamsViewModel
    @ObservedObject private var themeManager = ThemeManager.shared

    @Binding private var isShowingStreamInputView: Bool
    @Binding private var isShowingStreamingView: Bool
    @Binding private var isShowingFullStreamHistoryView: Bool
    @Binding private var isShowingSettingScreenView: Bool

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(
        viewModel: RecentStreamsViewModel,
        isShowingStreamInputView: Binding<Bool>,
        isShowingStreamingView: Binding<Bool>,
        isShowingFullStreamHistoryView: Binding<Bool>,
        isShowingSettingScreenView: Binding<Bool>
    ) {
        self.viewModel = viewModel
        _isShowingStreamInputView = isShowingStreamInputView
        _isShowingStreamingView = isShowingStreamingView
        _isShowingFullStreamHistoryView = isShowingFullStreamHistoryView
        _isShowingSettingScreenView = isShowingSettingScreenView
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
            .padding([.leading, .trailing], horizontalSizeClass == .regular ? Layout.spacing5x : Layout.spacing3x)
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
            viewModel: .init(),
            isShowingStreamInputView: .constant(false),
            isShowingStreamingView: .constant(false),
            isShowingFullStreamHistoryView: .constant(false),
            isShowingSettingScreenView: .constant(false)
        )
    }
}
#endif

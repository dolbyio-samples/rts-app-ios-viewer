//
//  RecentStreamsScreen.swift
//

import DolbyIOUIKit
import RTSComponentKit
import SwiftUI

struct RecentStreamsScreen: View {
    @Binding private var streamName: String
    @Binding private var accountID: String
    @Binding private var isShowingRecentStreams: Bool
    private let action: () -> Void

    private let theme = ThemeManager.shared.theme
    private let viewModel: RecentStreamsViewModel

    init(
        streamName: Binding<String>,
        accountID: Binding<String>,
        isShowingRecentStreams: Binding<Bool>,
        action: @escaping () -> Void
    ) {
        self._streamName = streamName
        self._accountID = accountID
        self._isShowingRecentStreams = isShowingRecentStreams
        self.action = action
        self.viewModel = RecentStreamsViewModel()
    }

    var body: some View {
        ZStack {
            GeometryReader { _ in
                VStack(spacing: Layout.spacing4x) {
                    Text(
                        text: "recent-streams.title.label",
                        fontAsset: .avenirNextDemiBold(
                            size: FontSize.title2,
                            style: .title2
                        )
                    )

                    HStack(spacing: Layout.spacing1x) {
                        Text("recent-streams.stream-name.label")
                            .font(
                                theme[
                                    .avenirNextMedium(
                                        size: FontSize.caption2,
                                        style: .caption2
                                    )
                                ]
                            )
                            .foregroundColor(Color(uiColor: UIColor.Neutral.neutral200))
                            .padding([.leading, .trailing])
                            .frame(maxWidth: .infinity)
                            .background(
                                Color(uiColor: UIColor.Neutral.neutral800),
                                in: RoundedRectangle(cornerRadius: Layout.cornerRadius4x)
                            )

                        Text("recent-streams.account-id.label")
                            .font(
                                theme[
                                    .avenirNextMedium(
                                        size: FontSize.caption2,
                                        style: .caption2
                                    )
                                ]
                            )
                            .foregroundColor(Color(uiColor: UIColor.Neutral.neutral200))
                            .padding([.leading, .trailing])
                            .frame(maxWidth: .infinity)
                            .background(
                                Color(uiColor: UIColor.Neutral.neutral800),
                                in: RoundedRectangle(cornerRadius: Layout.cornerRadius4x)
                            )
                    }
                    .padding([.leading, .trailing])
 #if os(tvOS)
                    .frame(width: 514.0)
 #endif
                    List {
                        ForEach(viewModel.streamDetails) { streamDetail in
                            if let streamName = streamDetail.streamName, let accountID = streamDetail.accountID {
                                RecentStreamButton(streamName: streamName, accountID: accountID) {
                                    self.streamName = streamName
                                    self.accountID = accountID
                                    isShowingRecentStreams = false
                                    action()
                                }
                            }
                        }
                    }
 #if os(tvOS)
                    .frame(width: 514.0)
 #endif
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(uiColor: UIColor.Neutral.neutral900))
    }
}

struct StreamHistoryScreen_Previews: PreviewProvider {
    static var previews: some View {
        RecentStreamsScreen(
            streamName: .constant(""),
            accountID: .constant(""),
            isShowingRecentStreams: .constant(false),
            action: {}
        )
    }
}

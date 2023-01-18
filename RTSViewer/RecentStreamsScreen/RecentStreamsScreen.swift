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
    @EnvironmentObject private var dataStore: RTSDataStore

    private let streamDetails: FetchRequest<StreamDetail> = FetchRequest<StreamDetail>(fetchRequest: PersistenceManager.recentStreams)

    init(streamName: Binding<String>, accountID: Binding<String>, isShowingRecentStreams: Binding<Bool>) {
        self._streamName = streamName
        self._accountID = accountID
        self._isShowingRecentStreams = isShowingRecentStreams
    }

    var body: some View {
        BackgroundContainerView {
            GeometryReader { proxy in
                VStack {
                    Text(
                        text: "recent-streams.title.label",
                        fontAsset: .avenirNextDemiBold(
                            size: FontSize.largeTitle,
                            style: .largeTitle
                        )
                    )

                    List {
                        ForEach(streamDetails.wrappedValue) { streamDetail in
                            if let name = streamDetail.streamName, let accountID = streamDetail.accountID {
                                SwiftUI.Button.init {
                                    self.streamName = name
                                    self.accountID = accountID
                                    isShowingRecentStreams = false

                                } label: {
                                    HStack {
                                        Spacer()
                                        Text("recent-streams.format.label \(name) \(accountID)")
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                    .frame(width: proxy.size.width / 2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct StreamHistoryScreen_Previews: PreviewProvider {
    static var previews: some View {
        RecentStreamsScreen(streamName: .constant(""), accountID: .constant(""), isShowingRecentStreams: .constant(false))
    }
}

//
//  ChannelDetailInputViewModel.swift
//

import Foundation
import RTSCore
import SwiftUI

struct StreamPair {
    let streamName: String
    let accountID: String
}

@MainActor
class ChannelDetailInputViewModel: ObservableObject {
    @Binding private var isShowingChannelView: Bool
    @Binding private var channels: [Channel]?

    @Published var streamName1: String = "game"
    @Published var accountID1: String = "7csQUs"
    @Published var streamName2: String = "multiview"
    @Published var accountID2: String = "k9Mwad"
    @Published var streamName3: String = "game"
    @Published var accountID3: String = "7csQUs"
    @Published var streamName4: String = "multiview"
    @Published var accountID4: String = "k9Mwad"

    init(
        channels: Binding<[Channel]?>, isShowingChannelView: Binding<Bool>) {
        self._channels = channels
        self._isShowingChannelView = isShowingChannelView
    }

    func playButtonPressed() {
        var confirmedChannels = [Channel]()
        let streamDetails = createStreamDetailArray()
        for detail in streamDetails {
            guard let channel = setupChannel(for: detail) else { return }
            confirmedChannels.append(channel)
        }
        guard !confirmedChannels.isEmpty else { return }
        channels = confirmedChannels
        isShowingChannelView = true
    }
}

private extension ChannelDetailInputViewModel {
    func setupChannel(for detail: StreamPair) -> Channel? {
        guard !detail.streamName.isEmpty, !detail.accountID.isEmpty else { return nil }
        return Channel(streamDetail: detail,
                       subscriptionManager: SubscriptionManager(),
                       rendererRegistry: RendererRegistry())
    }

    func createStreamDetailArray() -> [StreamPair] {
        var streamPairs = [StreamPair]()
        if !streamName1.isEmpty, !accountID1.isEmpty {
            let streamPair = StreamPair(streamName: streamName1, accountID: accountID1)
            streamPairs.append(streamPair)
        }
        if !streamName2.isEmpty, !accountID2.isEmpty {
            let streamPair = StreamPair(streamName: streamName2, accountID: accountID2)
            streamPairs.append(streamPair)
        }
        if !streamName3.isEmpty, !accountID3.isEmpty {
            let streamPair = StreamPair(streamName: streamName3, accountID: accountID3)
            streamPairs.append(streamPair)
        }
        if !streamName4.isEmpty, !accountID4.isEmpty {
            let streamPair = StreamPair(streamName: streamName4, accountID: accountID4)
            streamPairs.append(streamPair)
        }
        return streamPairs
    }

    func checkIfCredentialsAreValid(streamName: String, accountID: String) -> Bool {
        return streamName.count > 0 && accountID.count > 0
    }
}

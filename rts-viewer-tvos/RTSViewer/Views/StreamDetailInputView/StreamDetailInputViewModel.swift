//
//  StreamDetailInputViewModel.swift
//

import Combine
import Foundation
import MillicastSDK
import RTSCore
import SwiftUI

@MainActor
final class StreamDetailInputViewModel: ObservableObject {
    @Published private(set) var hasSavedStreams: Bool = false
    @Binding var streamName: String
    @Binding var accountID: String
    @Binding var playoutDelayMin: Int32?
    @Binding var playoutDelayMax: Int32?
    @Binding private var channels: [UnsourcedChannel]?
    @Binding var isShowingStreamingView: Bool
    @Binding private var isShowingChannelView: Bool
    @Published var isShowingRecentStreams: Bool = false
    @Published var isShowingErrorAlert = false
    @Published var isShowingClearStreamsAlert = false
    @Published var streamDetails: [StreamDetail] = [] {
        didSet {
            hasSavedStreams = !streamDetails.isEmpty
        }
    }

    let sdkVersion = "SDK Version \(MCLogger.getVersion())"
    var appVersion: String = ""
    private let streamDataManager: StreamDataManagerProtocol
    private var subscriptions: [AnyCancellable] = []

    init(
        streamName: Binding<String>,
        accountID: Binding<String>,
        playoutDelayMin: Binding<Int32?>,
        playoutDelayMax: Binding<Int32?>,
        channels: Binding<[UnsourcedChannel]?>,
        isShowingStreamingView: Binding<Bool>,
        isShowingChannelView: Binding<Bool>,
        isShowingRecentStreams: Binding<Bool>,
        streamDataManager: StreamDataManagerProtocol = StreamDataManager.shared
    ) {
        self._streamName = streamName
        self._accountID = accountID
        self._playoutDelayMin = playoutDelayMin
        self._playoutDelayMax = playoutDelayMax
        self._channels = channels
        self._isShowingStreamingView = isShowingStreamingView
        self._isShowingChannelView = isShowingChannelView
        self.streamDataManager = streamDataManager

        streamDataManager.streamDetailsSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] streamDetails in
                self?.streamDetails = streamDetails
            }
            .store(in: &subscriptions)
    }

    func playStream() {
        Task {
            guard checkIfCredentialsAreValid(streamName: streamName, accountID: accountID) else {
                isShowingErrorAlert = true
                return
            }

            saveStream(streamName: streamName, accountID: accountID)
            isShowingStreamingView = true
        }
    }

    func playFromConfig() {
        var confirmedChannels = [UnsourcedChannel]()
        let streamConfigs = getStreamConfigArray()
        streamConfigs.forEach {
            guard let channel = setupChannel(for: $0) else { return }
            confirmedChannels.append(channel)
        }

        guard !confirmedChannels.isEmpty else { return }
        channels = confirmedChannels
        isShowingChannelView = true
    }
}

private extension StreamDetailInputViewModel {
    func checkIfCredentialsAreValid(streamName: String, accountID: String) -> Bool {
        return streamName.count > 0 && accountID.count > 0
    }

    func saveStream(streamName: String, accountID: String) {
        streamDataManager.saveStream(streamName, accountID: accountID)
    }

    // TODO: Temporary until we have an online config to pull from
    func getStreamConfigArray() -> [StreamConfig] {
        let config1 = StreamConfig(apiUrl: "https://director.millicast.com/api/director/subscribe",
                                   streamName: "multiview",
                                   accountId: "k9Mwad")

        let config2 = StreamConfig(apiUrl: "https://director.millicast.com/api/director/subscribe",
                                   streamName: "game",
                                   accountId: "7csQUs")

        let config3 = StreamConfig(apiUrl: "https://director.millicast.com/api/director/subscribe",
                                   streamName: "multiview",
                                   accountId: "k9Mwad")

        let config4 = StreamConfig(apiUrl: "https://director.millicast.com/api/director/subscribe",
                                   streamName: "game",
                                   accountId: "7csQUs")
        return [config1, config2, config3, config4]
    }

    func setupChannel(for config: StreamConfig) -> UnsourcedChannel? {
        let subscriptionManager = SubscriptionManager()
        return UnsourcedChannel(streamConfig: config,
                                subscriptionManager: subscriptionManager)
    }
}

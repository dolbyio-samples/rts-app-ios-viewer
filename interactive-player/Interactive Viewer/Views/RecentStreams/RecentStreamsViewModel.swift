//
//  RecentStreamsViewModel.swift
//

import Combine
import Foundation
import DolbyIORTSCore
import MillicastSDK

@MainActor
final class RecentStreamsViewModel: ObservableObject {

    private let streamDataManager: StreamDataManagerProtocol
    private let settingsManager: SettingsManager
    private let dateProvider: DateProvider
    private var subscriptions: [AnyCancellable] = []

    let subscriptionManager: SubscriptionManager

    @Published private(set) var streamDetails: [SavedStreamDetail] = [] {
        didSet {
            lastPlayedStream = streamDetails.first
            topStreamDetails = Array(streamDetails.prefix(3))
        }
    }
    @Published private(set) var topStreamDetails: [SavedStreamDetail] = []
    @Published private(set) var lastPlayedStream: SavedStreamDetail?

    init(
        subscriptionManager: SubscriptionManager = SubscriptionManager(),
        streamDataManager: StreamDataManagerProtocol = StreamDataManager.shared,
        settingsManager: SettingsManager = .shared,
        dateProvider: DateProvider = DefaultDateProvider()
    ) {
        self.subscriptionManager = subscriptionManager
        self.streamDataManager = streamDataManager
        self.settingsManager = settingsManager
        self.dateProvider = dateProvider
        streamDataManager.streamDetailsSubject
            .sink { [weak self] streamDetails in
                guard let self = self else { return }
                Task {
                    await MainActor.run {
                        self.streamDetails = streamDetails
                    }
                }
            }
        .store(in: &subscriptions)
    }

    func fetchAllStreams() {
        streamDataManager.fetchStreamDetails()
    }

    func delete(at offsets: IndexSet) {
        Task { [weak self] in
            guard let self = self else { return }
            let currentStreamDetails = self.streamDetails

            offsets.forEach {
                let streamDetail = currentStreamDetails[$0]
                self.settingsManager.removeSettings(
                    for: .stream(
                        streamName: streamDetail.streamName,
                        accountID: streamDetail.accountID
                    )
                )
                self.streamDataManager.delete(streamDetail: streamDetail)
            }
        }
    }

    func clearAllStreams() {
        Task { [weak self] in
            guard let self = self else { return }
            let streamDetailsToDelete = self.streamDetails
            streamDetailsToDelete.forEach { streamDetail in
                self.settingsManager.removeSettings(
                    for: .stream(
                        streamName: streamDetail.streamName,
                        accountID: streamDetail.accountID
                    )
                )
                self.streamDataManager.delete(streamDetail: streamDetail)
            }
        }
    }

    func connect(streamDetail: SavedStreamDetail, saveLogs: Bool) -> Bool {
        streamDataManager.updateLastUsedDate(for: streamDetail)

        let currentDate = dateProvider.now
        let rtcLogPath = saveLogs ? URL.rtcLogPath(for: currentDate) : nil
        let sdkLogPath = saveLogs ? URL.sdkLogPath(for: currentDate) : nil

        let configuration = SubscriptionConfiguration(
            useDevelopmentServer: streamDetail.useDevelopmentServer,
            jitterMinimumDelayMs: streamDetail.videoJitterMinimumDelayInMs,
            disableAudio: streamDetail.disableAudio,
            rtcEventLogPath: rtcLogPath?.path,
            sdkLogPath: sdkLogPath?.path,
            minPlayoutDelay: streamDetail.minPlayoutDelay,
            maxPlayoutDelay: streamDetail.maxPlayoutDelay
        )

        Task { [weak self] in
            guard let self else { return }
            _ = try await self.subscriptionManager.subscribe(
                streamName: streamDetail.streamName,
                accountID: streamDetail.accountID,
                configuration: configuration
            )
        }

        return true
    }
}

//
//  RecentStreamsViewModel.swift
//

import Combine
import Foundation
import MillicastSDK
import RTSCore

@MainActor
final class RecentStreamsViewModel: ObservableObject {
    private let streamDataManager: StreamDataManagerProtocol
    private let settingsManager: SettingsManager
    private let dateProvider: DateProvider
    private var subscriptions: [AnyCancellable] = []

    @Published private(set) var streamDetails: [SavedStreamDetail] = [] {
        didSet {
            lastPlayedStream = streamDetails.first
            topStreamDetails = Array(streamDetails.prefix(3))
        }
    }

    @Published private(set) var topStreamDetails: [SavedStreamDetail] = []
    @Published private(set) var lastPlayedStream: SavedStreamDetail?

    init(
        streamDataManager: StreamDataManagerProtocol = StreamDataManager.shared,
        settingsManager: SettingsManager = .shared,
        dateProvider: DateProvider = DefaultDateProvider()
    ) {
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

    func updateLastUsedDate(for streamDetail: SavedStreamDetail) {
        streamDataManager.updateLastUsedDate(for: streamDetail)
    }

    func configuration(for streamDetail: SavedStreamDetail) -> SubscriptionConfiguration {
        let currentDate = dateProvider.now
        let rtcLogPath = streamDetail.saveLogs ? URL.rtcLogPath(for: currentDate) : nil
        let sdkLogPath = streamDetail.saveLogs ? URL.sdkLogPath(for: currentDate) : nil
        var playoutDelay = MCForcePlayoutDelay(min: Int32(streamDetail.minPlayoutDelay),
                                               max: Int32(streamDetail.maxPlayoutDelay))

        return SubscriptionConfiguration(
            subscribeAPI: streamDetail.subscribeAPI,
            jitterMinimumDelayMs: streamDetail.videoJitterMinimumDelayInMs,
            maxBitrate: streamDetail.maxBitrate,
            disableAudio: streamDetail.disableAudio,
            rtcEventLogPath: rtcLogPath?.path,
            sdkLogPath: sdkLogPath?.path,
            playoutDelay: playoutDelay,
            forceSmooth: streamDetail.forceSmooth,
            bweMonitorDurationUs: streamDetail.monitorDuration,
            bweRateChangePercentage: streamDetail.rateChangePercentage,
            upwardsLayerWaitTimeMs: streamDetail.upwardsLayerWaitTimeMs
        )
    }
}

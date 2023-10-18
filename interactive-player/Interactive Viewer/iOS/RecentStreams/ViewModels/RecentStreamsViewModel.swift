//
//  RecentStreamsViewModel.swift
//

import Combine
import Foundation
import DolbyIORTSUIKit
import DolbyIORTSCore

final class RecentStreamsViewModel: ObservableObject {

    private let streamDataManager: StreamDataManagerProtocol
    private var subscriptions: [AnyCancellable] = []
    private let settingsManager: SettingsManager
    private let dateProvider: DateProvider

    @MainActor @Published private(set) var streamDetails: [SavedStreamDetail] = [] {
        didSet {
            lastPlayedStream = streamDetails.first
            topStreamDetails = Array(streamDetails.prefix(3))
        }
    }
    @MainActor @Published private(set) var topStreamDetails: [SavedStreamDetail] = []
    @MainActor @Published private(set) var lastPlayedStream: SavedStreamDetail?

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
            let currentStreamDetails = await self.streamDetails

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
            let streamDetailsToDelete = await self.streamDetails
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

    func connect(streamDetail: SavedStreamDetail, saveLogs: Bool) async -> Bool {
        let currentDate = dateProvider.now
        let rtcLogPath = saveLogs ? URL.rtcLogPath(for: currentDate) : nil
        let sdkLogPath = saveLogs ? URL.sdkLogPath(for: currentDate) : nil

        let configuration = SubscriptionConfiguration(
            useDevelopmentServer: streamDetail.useDevelopmentServer,
            videoJitterMinimumDelayInMs: streamDetail.videoJitterMinimumDelayInMs,
            noPlayoutDelay: streamDetail.noPlayoutDelay,
            disableAudio: streamDetail.disableAudio,
            rtcEventLogPath: rtcLogPath?.path,
            sdkLogPath: sdkLogPath?.path
        )

        let success = await StreamOrchestrator.shared.connect(
            streamName: streamDetail.streamName,
            accountID: streamDetail.accountID,
            configuration: configuration
        )

        if success {
            streamDataManager.updateLastUsedDate(for: streamDetail)
        } else {
            // No-op
        }
        return success
    }
}

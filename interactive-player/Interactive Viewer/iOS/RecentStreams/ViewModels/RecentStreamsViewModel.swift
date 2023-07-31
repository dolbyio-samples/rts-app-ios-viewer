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

    @Published private(set) var streamDetails: [StreamDetail] = [] {
        didSet {
            lastPlayedStream = streamDetails.first
            topStreamDetails = Array(streamDetails.prefix(3))
        }
    }
    @Published private(set) var topStreamDetails: [StreamDetail] = []
    @Published private(set) var lastPlayedStream: StreamDetail?

    init(
        streamDataManager: StreamDataManagerProtocol = StreamDataManager.shared,
        settingsManager: SettingsManager = .shared
    ) {
        self.streamDataManager = streamDataManager
        self.settingsManager = settingsManager
        streamDataManager.streamDetailsSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] streamDetails in
                self?.streamDetails = streamDetails
            }
        .store(in: &subscriptions)
    }

    func fetchAllStreams() {
        streamDataManager.fetchStreamDetails()
    }

    func delete(at offsets: IndexSet) {
        offsets.forEach {
            let streamDetail = streamDetails[$0]
            settingsManager.removeSettings(for: .stream(streamName: streamDetail.streamName, accountID: streamDetail.accountID))
            streamDataManager.delete(streamDetail: streamDetail)
        }
    }

    func clearAllStreams() {
        streamDetails.forEach { streamDetail in
            settingsManager.removeSettings(for: .stream(streamName: streamDetail.streamName, accountID: streamDetail.accountID))
            streamDataManager.delete(streamDetail: streamDetail)
        }
    }

    func connect(streamName: String, accountID: String) async -> Bool {
        await StreamOrchestrator.shared.connect(streamName: streamName, accountID: accountID)
    }

    func saveStream(streamName: String, accountID: String) {
        streamDataManager.saveStream(streamName, accountID: accountID)
    }
}

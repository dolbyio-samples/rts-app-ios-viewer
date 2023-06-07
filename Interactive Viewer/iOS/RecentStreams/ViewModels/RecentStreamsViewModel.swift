//
//  RecentStreamsViewModel.swift
//

import Combine
import Foundation
import DolbyIORTSCore

final class RecentStreamsViewModel: ObservableObject {

    private let streamDataManager: StreamDataManagerProtocol
    private var subscriptions: [AnyCancellable] = []

    @Published private(set) var streamDetails: [StreamDetail] = [] {
        didSet {
            lastPlayedStream = streamDetails.first
            topStreamDetails = Array(streamDetails.prefix(3))
        }
    }
    @Published private(set) var topStreamDetails: [StreamDetail] = []
    @Published private(set) var lastPlayedStream: StreamDetail?

    init(streamDataManager: StreamDataManagerProtocol = StreamDataManager.shared) {
        self.streamDataManager = streamDataManager
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
            streamDataManager.delete(streamDetail: streamDetail)
            _ = SettingsManager.shared.removeSettings(for: streamDetail.streamName, with: streamDetail.accountID)
        }
    }

    func clearAllStreams() {
        streamDataManager.clearAllStreams()
    }

    func connect(streamName: String, accountID: String) async -> Bool {
        await StreamCoordinator.shared.connect(streamName: streamName, accountID: accountID)
    }

    func saveStream(streamName: String, accountID: String) {
        streamDataManager.saveStream(streamName, accountID: accountID)
    }
}

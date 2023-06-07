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
            streamDataManager.delete(streamDetail: streamDetails[$0])
            let streamDetail = DolbyIORTSCore.StreamDetail(streamName: streamDetails[$0].streamName, accountID: streamDetails[$0].accountID)
            _ = SettingsManager.shared.removeSettings(for: streamDetail.streamId)
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

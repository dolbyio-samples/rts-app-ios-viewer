//
//  RecentStreamsViewModel.swift
//

import Combine
import Foundation
import RTSComponentKit

final class RecentStreamsViewModel: ObservableObject {

    let dataStore: RTSDataStore
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

    init(streamDataManager: StreamDataManagerProtocol = StreamDataManager.shared, dataStore: RTSDataStore = .init()) {
        self.dataStore = dataStore
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

    func clearAllStreams() {
        streamDataManager.clearAllStreams()
    }

    func connect(streamName: String, accountID: String) async -> Bool {
        return await dataStore.connect(streamName: streamName, accountID: accountID)
    }

    func saveStream(streamName: String, accountID: String) {
        streamDataManager.saveStream(streamName, accountID: accountID)
    }
}

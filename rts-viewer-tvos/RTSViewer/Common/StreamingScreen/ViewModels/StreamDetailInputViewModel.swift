//
//  StreamDetailInputViewModel.swift
//

import Combine
import Foundation
import RTSComponentKit

final class StreamDetailInputViewModel: ObservableObject {
    let dataStore: RTSDataStore
    private let streamDataManager: StreamDataManagerProtocol

    private var subscriptions: [AnyCancellable] = []

    @Published var streamDetails: [StreamDetail] = [] {
        didSet {
            hasSavedStreams = !streamDetails.isEmpty
        }
    }
    @Published private(set) var hasSavedStreams: Bool = false

    init(
        dataStore: RTSDataStore = .init(),
        streamDataManager: StreamDataManagerProtocol = StreamDataManager.shared
    ) {
        self.dataStore = dataStore
        self.streamDataManager = streamDataManager

        streamDataManager.streamDetailsSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] streamDetails in
                self?.streamDetails = streamDetails
            }
        .store(in: &subscriptions)
    }

    func checkIfCredentialsAreValid(streamName: String, accountID: String) -> Bool {
        return streamName.count > 0 && accountID.count > 0
    }

    func connect(streamName: String, accountID: String) async throws -> Bool {
        try await dataStore.connect(streamName: streamName, accountID: accountID)
    }

    func saveStream(streamName: String, accountID: String) {
        streamDataManager.saveStream(streamName, accountID: accountID)
    }

    func clearAllStreams() {
        streamDataManager.clearAllStreams()
    }
}

//
//  StreamDetailInputViewModel.swift
//

import Combine
import Foundation
import RTSComponentKit

@MainActor
final class StreamDetailInputViewModel: ObservableObject {
    let subscriptionManager: SubscriptionManager
    private let streamDataManager: StreamDataManagerProtocol

    private var subscriptions: [AnyCancellable] = []

    @Published var streamDetails: [StreamDetail] = [] {
        didSet {
            hasSavedStreams = !streamDetails.isEmpty
        }
    }
    @Published private(set) var hasSavedStreams: Bool = false

    init(
        subscriptionManager: SubscriptionManager = SubscriptionManager(),
        streamDataManager: StreamDataManagerProtocol = StreamDataManager.shared
    ) {
        self.subscriptionManager = subscriptionManager
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

    func connect(streamName: String, accountID: String) async throws {
        try await subscriptionManager.subscribe(streamName: streamName, accountID: accountID)
    }

    func saveStream(streamName: String, accountID: String) {
        streamDataManager.saveStream(streamName, accountID: accountID)
    }

    func clearAllStreams() {
        streamDataManager.clearAllStreams()
    }
}

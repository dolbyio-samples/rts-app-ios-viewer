//
//  StreamDetailInputViewModel.swift
//

import Combine
import Foundation
import DolbyIORTSCore

final class StreamDetailInputViewModel: ObservableObject {
    let streamCoordinator: StreamCoordinator
    private let streamDataManager: StreamDataManagerProtocol

    private var subscriptions: [AnyCancellable] = []

    @Published var streamDetails: [StreamDetail] = [] {
        didSet {
            hasSavedStreams = !streamDetails.isEmpty
        }
    }
    @Published private(set) var hasSavedStreams: Bool = false

    init(
        streamCoordinator: StreamCoordinator = .shared,
        streamDataManager: StreamDataManagerProtocol = StreamDataManager.shared
    ) {
        self.streamCoordinator = streamCoordinator
        self.streamDataManager = streamDataManager

        streamDataManager.streamDetailsSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] streamDetails in
                self?.streamDetails = streamDetails
            }
        .store(in: &subscriptions)
    }

    func connect(streamName: String, accountID: String) async -> Bool {
        return await streamCoordinator.connect(streamName: streamName, accountID: accountID)
    }

    func saveStream(streamName: String, accountID: String) {
        streamDataManager.saveStream(streamName, accountID: accountID)
    }

    func clearAllStreams() {
        streamDataManager.clearAllStreams()
    }
}
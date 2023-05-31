//
//  StreamDetailInputViewModel.swift
//

import Combine
import Foundation
import DolbyIORTSCore

final class StreamDetailInputViewModel: ObservableObject {
    let streamCoordinator: StreamCoordinator
    private let streamDataManager: StreamDataManagerProtocol
    let identifier = UUID()
    
    init(
        streamCoordinator: StreamCoordinator = .shared,
        streamDataManager: StreamDataManagerProtocol = StreamDataManager.shared
    ) {
        self.streamCoordinator = streamCoordinator
        self.streamDataManager = streamDataManager
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

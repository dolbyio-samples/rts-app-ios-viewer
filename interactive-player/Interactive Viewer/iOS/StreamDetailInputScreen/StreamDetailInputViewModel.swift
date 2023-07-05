//
//  StreamDetailInputViewModel.swift
//

import Combine
import Foundation
import DolbyIORTSCore

final class StreamDetailInputViewModel: ObservableObject {
    let streamOrchestrator: StreamOrchestrator
    private let streamDataManager: StreamDataManagerProtocol

    init(
        streamOrchestrator: StreamOrchestrator = .shared,
        streamDataManager: StreamDataManagerProtocol = StreamDataManager.shared
    ) {
        self.streamOrchestrator = streamOrchestrator
        self.streamDataManager = streamDataManager
    }

//    func connect(streamName: String, accountID: String) async -> Bool {
//        return await streamOrchestrator.connect(streamName: streamName, accountID: accountID)
//    }

    func saveStream(streamName: String, accountID: String) {
        streamDataManager.saveStream(streamName, accountID: accountID)
    }

    func clearAllStreams() {
        streamDataManager.clearAllStreams()
    }
}

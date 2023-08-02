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

    // swiftlint:disable function_parameter_count
    func saveStream(
        streamName: String,
        accountID: String,
        dev: Bool,
        forcePlayoutDelay: Bool,
        disableAudio: Bool,
        jitterBufferDelay: Int,
        saveLogs: Bool
    ) {
        streamDataManager.saveStream(
            streamName,
            accountID: accountID,
            dev: dev,
            forcePlayoutDelay: forcePlayoutDelay,
            disableAudio: disableAudio,
            jitterBufferDelay: jitterBufferDelay,
            saveLogs: saveLogs
        )
    }
    // swiftlint:enable function_parameter_count

    func clearAllStreams() {
        streamDataManager.clearAllStreams()
    }
}

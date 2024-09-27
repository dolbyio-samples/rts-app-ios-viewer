//
//  StreamDetailInputViewModel.swift
//

import Combine
import Foundation
import MillicastSDK
import RTSCore

@MainActor
final class StreamDetailInputViewModel: ObservableObject {
    @Published private(set) var hasSavedStreams: Bool = false
    @Published var streamDetails: [StreamDetail] = [] {
        didSet {
            hasSavedStreams = !streamDetails.isEmpty
        }
    }

    let sdkVersion = "SDK Version \(MCLogger.getVersion())"
    var appVersion: String = ""
    private let streamDataManager: StreamDataManagerProtocol
    private var subscriptions: [AnyCancellable] = []

    init(streamDataManager: StreamDataManagerProtocol = StreamDataManager.shared) {
        self.streamDataManager = streamDataManager

        if let version = Bundle.main.releaseVersionNumber,
           let build = Bundle.main.buildVersionNumber
        {
            appVersion = "App Version \(version) \(build)"
        }

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

    func saveStream(streamName: String, accountID: String) {
        streamDataManager.saveStream(streamName, accountID: accountID)
    }

    func clearAllStreams() {
        streamDataManager.clearAllStreams()
    }
}

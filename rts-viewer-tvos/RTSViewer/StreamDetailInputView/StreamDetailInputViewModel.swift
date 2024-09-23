//
//  StreamDetailInputViewModel.swift
//

import Combine
import Foundation
import RTSCore

@MainActor
final class StreamDetailInputViewModel: ObservableObject {
    private let streamDataManager: StreamDataManagerProtocol

    private var subscriptions: [AnyCancellable] = []

    @Published var streamDetails: [StreamDetail] = [] {
        didSet {
            hasSavedStreams = !streamDetails.isEmpty
        }
    }
    @Published private(set) var hasSavedStreams: Bool = false

    @Published private(set) var appVersion: String = ""
    @Published private(set) var sdkVersion: String = ""

    init(streamDataManager: StreamDataManagerProtocol = StreamDataManager.shared) {
        self.streamDataManager = streamDataManager

        if let version = Bundle.main.releaseVersionNumber,
           let build = Bundle.main.buildVersionNumber {
            appVersion = "App Version \(version).\(build)"
        }

        sdkVersion = "SDK Version \(Constants.sdkVersion)"

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

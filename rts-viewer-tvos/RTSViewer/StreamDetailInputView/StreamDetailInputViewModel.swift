//
//  StreamDetailInputViewModel.swift
//

import Combine
import Foundation
import RTSCore

@MainActor
final class StreamDetailInputViewModel: ObservableObject {
    @Published var streamName: String = ""
    @Published var accountID: String = ""

    @Published var isShowingStreamingView: Bool = false
    @Published var isShowingChannelView: Bool = false
    @Published var isShowingRecentStreams: Bool = false
    @Published var isShowingErrorAlert = false
    @Published var isShowingClearStreamsAlert = false

    private let streamDataManager: StreamDataManagerProtocol

    private var subscriptions: [AnyCancellable] = []

    @Published var streamDetails: [StreamDetail] = [] {
        didSet {
            hasSavedStreams = !streamDetails.isEmpty
        }
    }

    @Published private(set) var hasSavedStreams: Bool = false

    init(streamDataManager: StreamDataManagerProtocol = StreamDataManager.shared) {
        self.streamDataManager = streamDataManager

        streamDataManager.streamDetailsSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] streamDetails in
                self?.streamDetails = streamDetails
            }
            .store(in: &subscriptions)
    }

    func playStream() {
        Task {
            guard checkIfCredentialsAreValid(streamName: streamName, accountID: accountID) else {
                isShowingErrorAlert = true
                return
            }

            saveStream(streamName: streamName, accountID: accountID)
            isShowingStreamingView = true
        }
    }

    func clearAllStreams() {
        streamDataManager.clearAllStreams()
    }
}

private extension StreamDetailInputViewModel {
    func checkIfCredentialsAreValid(streamName: String, accountID: String) -> Bool {
        return streamName.count > 0 && accountID.count > 0
    }

    func saveStream(streamName: String, accountID: String) {
        streamDataManager.saveStream(streamName, accountID: accountID)
    }
}

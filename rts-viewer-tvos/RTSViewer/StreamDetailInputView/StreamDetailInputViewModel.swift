//
//  StreamDetailInputViewModel.swift
//

import Combine
import Foundation
import RTSCore
import SwiftUI

@MainActor
final class StreamDetailInputViewModel: ObservableObject {
    @Binding var streamName: String
    @Binding var accountID: String
    @Binding var isShowingStreamingView: Bool
    @Published var isShowingRecentStreams: Bool = false
    @Published var isShowingErrorAlert = false
    @Published var isShowingClearStreamsAlert = false
    @Published private(set) var hasSavedStreams: Bool = false

    private let streamDataManager: StreamDataManagerProtocol
    private var subscriptions: [AnyCancellable] = []
    private var streamDetails: [StreamDetail] = [] {
        didSet {
            hasSavedStreams = !streamDetails.isEmpty
        }
    }

    init(
        streamName: Binding<String>,
        accountID: Binding<String>,
        isShowingStreamingView: Binding<Bool>,
        isShowingRecentStreams: Binding<Bool>,
        streamDataManager: StreamDataManagerProtocol = StreamDataManager.shared
    ) {
        self._streamName = streamName
        self._accountID = accountID
        self._isShowingStreamingView = isShowingStreamingView
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
}

private extension StreamDetailInputViewModel {
    func checkIfCredentialsAreValid(streamName: String, accountID: String) -> Bool {
        return streamName.count > 0 && accountID.count > 0
    }

    func saveStream(streamName: String, accountID: String) {
        streamDataManager.saveStream(streamName, accountID: accountID)
    }
}

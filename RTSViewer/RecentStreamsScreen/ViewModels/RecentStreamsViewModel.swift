//
//  RecentStreamsViewModel.swift
//

import Combine
import Foundation

final class RecentStreamsViewModel: ObservableObject {

    private let streamDataManager: StreamDataManagerProtocol
    private var subscriptions: [AnyCancellable] = []

    @Published var streamDetails: [StreamDetail] = []

    init(streamDataManager: StreamDataManagerProtocol = StreamDataManager.shared) {
        self.streamDataManager = streamDataManager
        streamDataManager.streamDetailsSubject
            .sink { streamDetails in
                self.streamDetails = streamDetails
            }
        .store(in: &subscriptions)
    }

    func fetchAllStreams() {
        streamDataManager.fetchStreamDetails()
    }
}

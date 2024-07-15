//
//  LandingViewModel.swift
//

import Combine
import Foundation
import RTSCore

final class LandingViewModel: ObservableObject {
    private let streamDataManager: StreamDataManagerProtocol
    private var subscriptions: [AnyCancellable] = []

    private var streamDetails: [SavedStreamDetail] = [] {
        didSet {
            let hasSavedStreamsOnLastUpdate = !streamDetails.isEmpty
            if hasSavedStreams != hasSavedStreamsOnLastUpdate {
                hasSavedStreams = hasSavedStreamsOnLastUpdate
            }
        }
    }
    @Published private(set) var hasSavedStreams: Bool = false

    init(streamDataManager: StreamDataManagerProtocol = StreamDataManager.shared) {
        self.streamDataManager = streamDataManager

        // Fetch saved streams
        streamDataManager.fetchStreamDetails()
    }

    func startStreamObservations() {
        streamDataManager.streamDetailsSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] streamDetails in
                self?.streamDetails = streamDetails
            }
        .store(in: &subscriptions)
    }
}

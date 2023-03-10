//
//  LandingViewModel.swift
//

import Combine
import Foundation

final class LandingViewModel: ObservableObject {
    private let streamDataManager: StreamDataManagerProtocol
    private var subscriptions: [AnyCancellable] = []

    private var streamDetails: [StreamDetail] = [] {
        didSet {
            hasSavedStreams = !streamDetails.isEmpty
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

    func stopStreamObservations() {
        subscriptions.removeAll()
    }
}

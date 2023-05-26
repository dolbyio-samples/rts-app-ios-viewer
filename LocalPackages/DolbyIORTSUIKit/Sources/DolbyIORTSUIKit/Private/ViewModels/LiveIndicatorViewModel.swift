//
//  LiveIndicatorViewModel.swift
//

import Combine
import DolbyIORTSCore
import Foundation

final class LiveIndicatorViewModel: ObservableObject {
    @Published private(set) var isStreamActive: Bool = false
    private let streamCoordinator: StreamCoordinator
    private var subscriptions: [AnyCancellable] = []

    init(streamCoordinator: StreamCoordinator = .shared) {
        self.streamCoordinator = streamCoordinator

        setupStateObservers()
    }

    private func setupStateObservers() {
        streamCoordinator.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                switch state {
                case let .subscribed(sources: sources, numberOfStreamViewers: _):
                    self.isStreamActive = !sources.isEmpty
                default:
                    break
                }
            }
            .store(in: &subscriptions)
    }
}

//
//  LiveIndicatorViewModel.swift
//

import Combine
import DolbyIORTSCore
import Foundation

final class LiveIndicatorViewModel: ObservableObject {
    @Published private(set) var isStreamActive: Bool = false
    private let streamOrchestrator: StreamOrchestrator
    private var subscriptions: [AnyCancellable] = []

    init(streamOrchestrator: StreamOrchestrator = .shared) {
        self.streamOrchestrator = streamOrchestrator

        setupStateObservers()
    }

    private func setupStateObservers() {
        Task { @StreamOrchestrator [weak self] in
            guard let self = self else { return }

            await self.streamOrchestrator.statePublisher
                .receive(on: DispatchQueue.main)
                .sink { state in
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
}

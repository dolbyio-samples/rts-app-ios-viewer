//
//  StreamViewModel.swift
//

import Combine
import DolbyIORTSCore
import Foundation

final class StreamViewModel: ObservableObject {

    let streamCoordinator: StreamCoordinator

    private var subscriptions: [AnyCancellable] = []
    @Published private(set) var sources: [StreamSource] = []

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
                    self.sources = sources
                default:
                    break
                }
            }
            .store(in: &subscriptions)
    }
}

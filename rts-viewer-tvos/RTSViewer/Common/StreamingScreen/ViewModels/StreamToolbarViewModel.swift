//
//  StreamToolbarViewModel.swift
//

import Combine
import Foundation
import RTSComponentKit
import UIKit

final class StreamToolbarViewModel: ObservableObject {
    let dataStore: RTSDataStore
    private let persistentSettings: PersistentSettingsProtocol

    @Published private(set) var isStreamActive = false
    @Published var isLiveIndicatorEnabled: Bool {
        didSet {
            persistentSettings.liveIndicatorEnabled = isLiveIndicatorEnabled
        }
    }
    @Published private(set) var streamName: String?

    private var subscriptions: [AnyCancellable] = []

    init(
        dataStore: RTSDataStore,
        persistentSettings: PersistentSettingsProtocol = PersistentSettings()
    ) {
        self.dataStore = dataStore
        self.persistentSettings = persistentSettings
        self.isLiveIndicatorEnabled = persistentSettings.liveIndicatorEnabled

        setupStateObservers()
    }

    private func setupStateObservers() {
        dataStore.$subscribeState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                self.isStreamActive = (state == .streamActive)
            }
            .store(in: &subscriptions)

        dataStore.$streamName
            .receive(on: DispatchQueue.main)
            .sink {[weak self] streamName in
                self?.streamName = streamName
            }
            .store(in: &subscriptions)
    }
}

//
//  DisplayStreamViewModel.swift
//

import Combine
import Foundation
import MillicastSDK
import os
import RTSComponentKit
import UIKit

final class DisplayStreamViewModel: ObservableObject {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: DisplayStreamViewModel.self)
    )

    private let persistentSettings: PersistentSettingsProtocol
    private let networkMonitor: NetworkMonitor

    let dataStore: RTSDataStore

    @Published private(set) var selectedVideoQuality: VideoQuality = .auto
    @Published private(set) var videoQualityList: [VideoQuality] = []
    @Published private(set) var videoTrack: MCVideoTrack? {
        didSet {
            isStreamActive = videoTrack != nil
        }
    }
    @Published private(set) var isLiveIndicatorEnabled: Bool
    @Published private(set) var isStreamActive: Bool = false
    @Published private(set) var statisticsData: StatisticsData?
    @Published private(set) var isNetworkConnected: Bool = true

    private var subscriptions: [AnyCancellable] = []

    init(
        dataStore: RTSDataStore,
        persistentSettings: PersistentSettingsProtocol = PersistentSettings(),
        networkMonitor: NetworkMonitor = .shared
    ) {
        self.dataStore = dataStore
        self.persistentSettings = persistentSettings
        self.networkMonitor = networkMonitor
        isLiveIndicatorEnabled = persistentSettings.liveIndicatorEnabled

        setupStateObservers()
    }

    func updateLiveIndicator(_ enabled: Bool) {
        isLiveIndicatorEnabled = enabled
        persistentSettings.liveIndicatorEnabled = enabled
    }

    // swiftlint:disable function_body_length
    private func setupStateObservers() {
        dataStore.$state
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }

                Task {
                    switch state {
                    case .connected:
                        Self.logger.debug("🎰 Connected")
                        _ = try await self.dataStore.startSubscribe()
                        await MainActor.run {
                            self.isNetworkConnected = true
                        }

                    case let .subscribed(state: subscribedState):
                        Self.logger.debug("🎰 Subscribed")
                        await MainActor.run {
                            self.videoTrack = subscribedState.mainVideoTrack
                            self.statisticsData = subscribedState.statisticsData
                        }
                    case .stopped:
                        Self.logger.debug("🎰 Stopped")
                        await self.resetSubscribedState()

                    case .disconnected:
                        Self.logger.debug("🎰 Disconnected")

                    case .error(.connectError(status: 0, reason: _)):
                        Self.logger.debug("🎰 No internet connection")
                        await MainActor.run {
                            self.videoTrack = nil
                            self.statisticsData = nil
                            self.isNetworkConnected = false
                        }

                    case let .error(.connectError(status: status, reason: reason)):
                        Self.logger.debug("🎰 Connection error - \(status), \(reason)")
                        await self.resetSubscribedState()

                    case let .error(.signalingError(reason: reason)):
                        Self.logger.debug("🎰 Signaling error - \(reason)")
                        await self.resetSubscribedState()
                    }
                }
            }
            .store(in: &subscriptions)

        dataStore.$videoQualityList
            .receive(on: DispatchQueue.main)
            .sink { [weak self] layers in
                guard let self = self else { return }
                self.videoQualityList = layers
                Self.logger.debug("🎥 Received layers - \(layers)")

                if self.selectedVideoQuality != self.dataStore.selectedVideoQuality {
                    self.selectedVideoQuality = self.dataStore.selectedVideoQuality
                    Task {
                        try await self.setLayer(quality: self.selectedVideoQuality)
                    }
                }
            }
            .store(in: &subscriptions)

        dataStore.$selectedVideoQuality
            .receive(on: DispatchQueue.main)
            .sink { [weak self] videoQuality in
                Self.logger.debug("🎥 Updated selected layer")

                self?.selectedVideoQuality = videoQuality
            }
            .store(in: &subscriptions)
    }
    // swiftlint:enable function_body_length

    func setLayer(quality: VideoQuality) async throws {
        try await dataStore.selectLayer(videoQuality: quality)
    }

    func resetSubscribedState() async {
        await MainActor.run {
            self.videoTrack = nil
            self.statisticsData = nil
        }
    }

    func stopSubscribe() async throws {
        subscriptions.removeAll()
        _ = try await dataStore.stopSubscribe()
    }
}

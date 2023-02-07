//
//  DisplayStreamViewModel.swift
//

import Combine
import Foundation
import RTSComponentKit
import UIKit

final class DisplayStreamViewModel: ObservableObject {

    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    private let persistentSettings: PersistentSettingsProtocol
    private let networkMonitor: NetworkMonitor

    let dataStore: RTSDataStore

    @Published private(set) var selectedLayer: StreamType = .auto
    @Published private(set) var layersDisabled = true
    @Published private(set) var isStreamActive = false
    @Published private(set) var activeStreamTypes: [StreamType] = []
    @Published private(set) var isNetworkConnected = false
    @Published private(set) var statisticsData: StatisticsData?
    @Published var isLiveIndicatorEnabled: Bool {
        didSet {
            persistentSettings.liveIndicatorEnabled = isLiveIndicatorEnabled
        }
    }

    private var subscriptions: [AnyCancellable] = []

    init(
        dataStore: RTSDataStore,
        persistentSettings: PersistentSettingsProtocol = PersistentSettings(),
        networkMonitor: NetworkMonitor = .shared
    ) {
        self.dataStore = dataStore
        self.persistentSettings = persistentSettings
        self.networkMonitor = networkMonitor
        self.isLiveIndicatorEnabled = persistentSettings.liveIndicatorEnabled

        setupStateObservers()
    }

    // swiftlint:disable cyclomatic_complexity function_body_length
    private func setupStateObservers() {
        dataStore.$subscribeState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }

                Task {
                    switch state {
                    case .connected:
                        _ = await self.dataStore.startSubscribe()
                    case .streamInactive:
                        self.selectedLayer = StreamType.auto
                        _ = await self.dataStore.stopSubscribe()
                    case .disconnected:
                        self.layersDisabled = true
                    default:
                        // No-op
                        break
                    }
                }
                self.isStreamActive = (state == .streamActive)
            }
            .store(in: &subscriptions)

        dataStore.$layerActiveMap
            .receive(on: DispatchQueue.main)
            .sink { [weak self] layers in
                guard let self = self else { return }

                self.activeStreamTypes = self.dataStore.activeStreamType
                self.layersDisabled = layers.map { $0.count < 2 || $0.count > 3} ?? true

                if !self.layersDisabled && self.selectedLayer != self.dataStore.activeLayer {
                    self.setLayer(streamType: self.selectedLayer)
                }
            }
            .store(in: &subscriptions)

        dataStore.$activeLayer
            .receive(on: DispatchQueue.main)
            .sink { [weak self] activeLayer in
                self?.selectedLayer = activeLayer
            }
            .store(in: &subscriptions)

        timer
            .sink { [weak self] _ in
                guard let self = self else { return }

                Task {
                    switch self.dataStore.subscribeState {
                    case .error, .disconnected:
                        _ = await self.dataStore.connect()
                    default:
                        // No-op
                        break
                    }
                }
            }
            .store(in: &subscriptions)

        networkMonitor.startMonitoring { [weak self] path in
            guard let self = self else { return }

            self.isNetworkConnected = path.status == .satisfied
        }
    }
    // swiftlint:enable cyclomatic_complexity function_body_length

    var streamingView: UIView {
        dataStore.subscriptionView()
    }

    var videoFrameWidth: CGFloat? {
        CGFloat(dataStore.statisticsData?.video?.frameWidth ?? 1280)
    }

    var videoFrameHeight: CGFloat? {
        CGFloat(dataStore.statisticsData?.video?.frameHeight ?? 720)
    }

    func setLayer(streamType: StreamType) {
        dataStore.selectLayer(streamType: streamType)
    }

    func stopSubscribe() async {
        _ = await dataStore.stopSubscribe()
        timer.upstream.connect().cancel()
    }
}

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
    @Published private(set) var width: Double?
    @Published private(set) var height: Double?

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
                    self.selectedLayer = self.dataStore.activeLayer
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

        dataStore.$dimensions
            .receive(on: DispatchQueue.main)
            .sink {[weak self] dimensions in
                self?.width = Double(dimensions?.width ?? 0)
                self?.height = Double(dimensions?.height ?? 0)
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

        networkMonitor.startMonitoring { [weak self] success in
            guard let self = self else { return }

            self.isNetworkConnected = success
        }
    }
    // swiftlint:enable cyclomatic_complexity function_body_length

    var streamingView: UIView {
        dataStore.subscriptionView()
    }

    func setLayer(streamType: StreamType) {
        dataStore.selectLayer(streamType: streamType)
    }

    func stopSubscribe() async {
        _ = await dataStore.stopSubscribe()
        timer.upstream.connect().cancel()
    }

    /** Method to calculate video view width and height for the current screen size
        and current stream frameWidth / frameHeight.
        videoFrameWidth and videoFrameWidth are assumed to be greater than 0.
        params: crop = true if the view should be cropped and take the whole screen
        crop = false if the view should not be cropped.
        */
    func calculateVideoViewWidthHeight(screenWidth: Float, screenHeight: Float) -> (CGFloat, CGFloat) {
        var ratio: Float = 1.0
        var width, height: Float

        ratio = calculateAspectRatio(crop: true, screenWidth: screenWidth, screenHeight: screenHeight, frameWidth: videoFrameWidth, frameHeight: videoFrameHeight)

        width = videoFrameWidth * ratio
        height = videoFrameHeight * ratio

        return (CGFloat(width), CGFloat(height))
    }
}

// MARK: Helper methods

private extension DisplayStreamViewModel {
    var videoFrameWidth: Float {
        dataStore.dimensions?.width ?? 0
    }

    var videoFrameHeight: Float {
        dataStore.dimensions?.height ?? 0
    }

    func calculateAspectRatio(crop: Bool, screenWidth: Float, screenHeight: Float, frameWidth: Float, frameHeight: Float) -> Float {
        if frameWidth <= 0 || frameHeight <= 0 {
            return 0
        }
        var ratio: Float = 0
        var widthHeading: Bool = true
        if screenWidth >= frameWidth && screenHeight >= frameHeight {
            if (screenWidth / frameWidth) < (screenHeight / frameHeight) {
                widthHeading = !crop
            } else {
                widthHeading = crop
            }
        } else if screenWidth >= frameWidth {
            widthHeading = crop
        } else if screenHeight >= frameHeight {
            widthHeading = !crop
        } else {
            if (screenWidth / frameWidth) > (screenHeight / frameHeight) {
                widthHeading = crop
            } else {
                widthHeading = !crop
            }
        }
        if widthHeading {
            ratio = screenWidth / frameWidth
        } else {
            ratio = screenHeight / frameHeight
        }
        return ratio
    }
}

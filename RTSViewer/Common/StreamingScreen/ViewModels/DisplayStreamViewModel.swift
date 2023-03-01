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
    @Published private(set) var width: CGFloat = 0.0
    @Published private(set) var height: CGFloat = 0.0

    private var subscriptions: [AnyCancellable] = []

    private var screenDimension: Dimensions = .init(width: 0, height: 0) {
        didSet {
            recalculateVideoContentWidthAndHeight()
        }
    }

    private var showVideoFullScreen: Bool = false {
        didSet {
            recalculateVideoContentWidthAndHeight()
        }
    }

    init(
        dataStore: RTSDataStore,
        persistentSettings: PersistentSettingsProtocol = PersistentSettings(),
        networkMonitor: NetworkMonitor = .shared
    ) {
        self.dataStore = dataStore
        self.persistentSettings = persistentSettings
        self.networkMonitor = networkMonitor
        self.dataStore.selectLayer(streamType: .auto)

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
                        _ = await self.dataStore.stopSubscribe()
                        await MainActor.run {
                            self.selectedLayer = StreamType.auto
                        }
                    case .disconnected:
                        await MainActor.run {
                            self.layersDisabled = true
                        }
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
            .sink {[weak self] _ in
                guard let self = self else {
                    return
                }

                self.recalculateVideoContentWidthAndHeight()
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

            Task {
                await MainActor.run {
                    self.isNetworkConnected = success
                }
            }
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
        subscriptions.removeAll()
        timer.upstream.connect().cancel()
        _ = await dataStore.stopSubscribe()
    }

    func updateScreenSize(width: Float, height: Float) {
        screenDimension = .init(width: width, height: height)
    }

    func showVideoInFullScreen(_ fullScreen: Bool) {
        showVideoFullScreen = fullScreen
    }

    /** Method to propagate view width and height that will be cached and used
        to calculate video frameWidth / frameHeight to display.
        params: crop = true if the view should be cropped and take the whole screen
        crop = false if the view should not be cropped.
        width, height: current screen size
     */
    private func recalculateVideoContentWidthAndHeight() {
        guard screenWidth > 0, screenHeight > 0, videoHeight > 0, videoWidth > 0 else {
            return
        }

        let ratio = calculateAspectRatio(
            crop: showVideoFullScreen,
            screenWidth: screenWidth,
            screenHeight: screenHeight,
            frameWidth: videoWidth,
            frameHeight: videoHeight
        )

        let scaledWidth = videoWidth * ratio
        let scaledHeight = videoHeight * ratio
        width = CGFloat(scaledWidth)
        height = CGFloat(scaledHeight)
    }
}

// MARK: Helper methods

private extension DisplayStreamViewModel {
    var videoWidth: Float {
        dataStore.dimensions.width
    }

    var videoHeight: Float {
        dataStore.dimensions.height
    }

    var screenWidth: Float {
        screenDimension.width
    }

    var screenHeight: Float {
        screenDimension.height
    }

    func calculateAspectRatio(crop: Bool, screenWidth: Float, screenHeight: Float, frameWidth: Float, frameHeight: Float) -> Float {
        guard frameWidth > 0, frameHeight > 0 else {
            return 0.0
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

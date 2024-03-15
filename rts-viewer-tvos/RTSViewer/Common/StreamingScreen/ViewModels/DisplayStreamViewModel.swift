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

    @Published private(set) var selectedVideoQuality: VideoQuality = .auto
    @Published private(set) var videoQualityList: [VideoQuality] = []
    @Published private(set) var layersDisabled = true

    @Published private(set) var isStreamActive = false
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
                        _ = try await self.dataStore.startSubscribe()
                    case .streamInactive:
                        _ = try await self.dataStore.stopSubscribe()
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

        dataStore.$videoQualityList
            .receive(on: DispatchQueue.main)
            .sink { [weak self] layers in
                guard let self = self else { return }
                self.videoQualityList = layers
                self.layersDisabled = layers.count < 2

                if !self.layersDisabled && self.selectedVideoQuality != self.dataStore.selectedVideoQuality {
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
                self?.selectedVideoQuality = videoQuality
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
                        _ = try await self.dataStore.connect()
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

    func setLayer(quality: VideoQuality) async throws {
        try await dataStore.selectLayer(videoQuality: quality)
    }

    func stopSubscribe() async throws {
        subscriptions.removeAll()
        timer.upstream.connect().cancel()
        _ = try await dataStore.stopSubscribe()
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

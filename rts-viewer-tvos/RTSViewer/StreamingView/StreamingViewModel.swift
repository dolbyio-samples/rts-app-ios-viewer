//
//  StreamingViewModel.swift
//

import Combine
import Foundation
import MillicastSDK
import os
import RTSCore
import UIKit
import SwiftUI

@MainActor
final class StreamingViewModel: ObservableObject {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: StreamingViewModel.self)
    )

    private let streamName: String
    private let accountID: String
    private let persistentSettings: PersistentSettingsProtocol
    private var layersEventsObservationDictionary: [SourceID: Task<Void, Never>] = [:]
    private var stateObservation: Task<Void, Never>?
    private var reconnectionTimer: Timer?

    private var subscriptions: [AnyCancellable] = []

    enum ViewState: Equatable {
        case disconnected
        case streaming(source: StreamSource)
        case noNetwork(title: String)
        case streamNotPublished(title: String, subtitle: String, source: StreamSource?)
        case otherError(message: String)
    }

    @Published private(set) var state: ViewState = .disconnected
    @Published private(set) var isLiveIndicatorEnabled: Bool {
        didSet {
            persistentSettings.liveIndicatorEnabled = isLiveIndicatorEnabled
        }
    }
    @Published private(set) var videoQualityList: [VideoQuality] = [] {
        didSet {
            // Set video quality selection to auto if the layer is missing
            if !videoQualityList.contains(where: { $0.encodingId == selectedVideoQuality.encodingId }) {
                Self.logger.debug("♼ Reset layer to `auto`")
                switch state {
                case let .streaming(source: source):
                    select(videoQuality: .auto, for: source)
                default:
                    break
                }
            }
        }
    }
    @Published private(set) var selectedVideoQuality: VideoQuality = .auto
    @Published private(set) var streamStatistics: StreamStatistics?

    let subscriptionManager: SubscriptionManager
    let rendererRegistry: RendererRegistry

    init(
        streamName: String,
        accountID: String,
        subscriptionManager: SubscriptionManager = SubscriptionManager(),
        persistentSettings: PersistentSettingsProtocol = PersistentSettings(),
        rendererRegistry: RendererRegistry = RendererRegistry()
    ) {
        self.streamName = streamName
        self.accountID = accountID
        self.subscriptionManager = subscriptionManager
        self.persistentSettings = persistentSettings
        self.rendererRegistry = rendererRegistry

        isLiveIndicatorEnabled = persistentSettings.liveIndicatorEnabled

        Task(priority: .userInitiated) { [weak self] in
            await self?.setupStateObservers()
        }
        observeStreamStatistics()
    }

    @objc func subscribeToStream() {
        Task(priority: .userInitiated) {
            do {
                Self.logger.debug("🎰 Subscribe to stream with \(self.streamName), \(self.accountID)")
                try await subscriptionManager.subscribe(streamName: streamName, accountID: accountID)
            } catch {
                Self.logger.debug("🎰 Subscribe failed with error \(error.localizedDescription)")
                self.state = .otherError(message: error.localizedDescription)
            }
        }
    }

    func updateLiveIndicator(_ enabled: Bool) {
        isLiveIndicatorEnabled = enabled
    }

    func select(videoQuality: VideoQuality, for source: StreamSource) {
        guard videoQuality.encodingId != selectedVideoQuality.encodingId else {
            return
        }

        Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            do {
                Self.logger.debug("🎰 Select video quality")
                let renderer = self.rendererRegistry.acceleratedRenderer(for: source)
                self.selectedVideoQuality = videoQuality
                switch videoQuality {
                case .auto:
                    try await source.videoTrack.enable(renderer: renderer.underlyingRenderer, promote: true)
                case let .quality(underlyingLayer):
                    try await source.videoTrack.enable(renderer: renderer.underlyingRenderer, layer: MCRTSRemoteVideoTrackLayer(layer: underlyingLayer), promote: true)
                }
            } catch {
                Self.logger.debug("🎰 Select video quality error \(error.localizedDescription)")
            }
        }
    }

    // swiftlint: disable function_body_length cyclomatic_complexity
    private func setupStateObservers() async {
        stateObservation = Task(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }

            await self.subscriptionManager.$state
                .sink { state in
                    Task {
                        guard !Task.isCancelled else { return }

                        switch state {
                        case let .subscribed(sources: sources):
                            let activeVideoSources = sources.filter { $0.videoTrack.isActive }
                            Self.logger.debug("🎰 Subscribed, has \(activeVideoSources.count) active video sources")
                            guard let videoSource = activeVideoSources.first(where: { $0.sourceId == .main }) ?? activeVideoSources.first else {
                                self.state = .streamNotPublished(
                                    title: LocalizedStringKey("stream.offline.title.label").toString(),
                                    subtitle: LocalizedStringKey("stream.offline.subtitle.label").toString(),
                                    source: nil
                                )
                                self.clearLayerInformation()
                                return
                            }

                            switch self.state {
                            case let .streaming(source: previousSource):
                                Self.logger.debug("🎰 Disabling previous source \(previousSource.sourceId)")
                                if previousSource.audioTrack?.isActive == true {
                                    try await previousSource.audioTrack?.disable()
                                }
                                if previousSource.videoTrack.isActive {
                                    try await previousSource.videoTrack.disable()
                                }
                                self.clearLayerInformation()
                            default:
                                break
                            }

                            Self.logger.debug("🎰 Picked source \(videoSource.sourceId) for rendering")

                            Task(priority: .userInitiated) {
                                guard !Task.isCancelled else { return }

                                await self.observeLayerEvents(for: videoSource)
                            }

                            Task(priority: .high) {
                                guard !Task.isCancelled, videoSource.videoTrack.isActive else { return }

                                let renderer = self.rendererRegistry.acceleratedRenderer(for: videoSource)
                                try await videoSource.videoTrack.enable(renderer: renderer.underlyingRenderer, promote: true)
                                Self.logger.debug("🎰 Picked source \(videoSource.sourceId) for rendering")

                                if let audioTrack = videoSource.audioTrack, videoSource.videoTrack.isActive {
                                    Self.logger.debug("🎰 Picked source \(videoSource.sourceId) for audio")
                                    // Enable new audio track
                                    try await audioTrack.enable()
                                }

                                await MainActor.run {
                                    self.state = .streaming(source: videoSource)
                                }
                            }

                        case .disconnected:
                            Self.logger.debug("🎰 Disconnected")
                            guard !Task.isCancelled else { return }

                            self.state = .disconnected

                        case let .error(connectionError) where connectionError.status == 0:
                            Self.logger.debug("🎰 No internet connection")
                            guard !Task.isCancelled else { return }

                            self.state = .noNetwork(
                                title: LocalizedStringKey("stream.network.disconnected.label").toString()
                            )

                        case let .error(connectionError):
                            Self.logger.debug("🎰 Connection error - \(connectionError.status), \(connectionError.reason)")
                            guard !Task.isCancelled else { return }
                            self.scheduleReconnection()
                            self.state = .streamNotPublished(
                                title: LocalizedStringKey("stream.offline.title.label").toString(),
                                subtitle: LocalizedStringKey("stream.offline.subtitle.label").toString(),
                                source: nil
                            )
                        }
                    }
                }
                .store(in: &subscriptions)
        }
        await stateObservation?.value
    }
    // swiftlint: enable function_body_length cyclomatic_complexity

    func stopSubscribe() {
        Task(priority: .userInitiated) {
            guard !Task.isCancelled else { return }
            do {
                Self.logger.debug("🎰 Subscribe to stream with \(self.streamName), \(self.accountID)")
                reset()
                _ = try await subscriptionManager.unSubscribe()
                Self.logger.debug("🎰 Unsubscribed successfully")
                state = .disconnected
            } catch {
                Self.logger.debug("🎰 Unsubscribe failed with error \(error.localizedDescription)")
                self.state = .otherError(message: error.localizedDescription)
            }
        }
    }
}

// MARK: Track lifecycle events

extension StreamingViewModel {

    func observeLayerEvents(for source: StreamSource) async {
        if layersEventsObservationDictionary[source.sourceId] != nil {
            layersEventsObservationDictionary[source.sourceId]?.cancel()
            layersEventsObservationDictionary[source.sourceId] = nil
        }

        Self.logger.debug("♼ Registering layer events for \(source.sourceId)")
        let layerEventsObservationTask = Task {
            for await layerEvent in source.videoTrack.layers() {
                guard !Task.isCancelled else { return }

                let videoQualities = layerEvent.layers()
                    .map(VideoQuality.init)
                    .reduce([.auto]) { $0 + [$1] }
                Self.logger.debug("♼ Received layers \(videoQualities.count)")
                self.videoQualityList = videoQualities
            }
        }

        layersEventsObservationDictionary[source.sourceId] = layerEventsObservationTask

        _ = await layerEventsObservationTask.value
    }

    func reset() {
        Self.logger.debug("🎰 Remove all observations")
        subscriptions.removeAll()
        layersEventsObservationDictionary.forEach { (sourceId, _) in
            layersEventsObservationDictionary[sourceId]?.cancel()
            layersEventsObservationDictionary[sourceId] = nil
        }
        stateObservation?.cancel()
        reconnectionTimer?.invalidate()
        reconnectionTimer = nil
        clearLayerInformation()
        streamStatistics = nil
    }

    func clearLayerInformation() {
        videoQualityList.removeAll()
        selectedVideoQuality = .auto
    }

    func scheduleReconnection() {
        self.reconnectionTimer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(subscribeToStream), userInfo: nil, repeats: false)
    }

    func observeStreamStatistics() {
        Task { [weak self] in
            guard let self else { return }
            await subscriptionManager.$streamStatistics
                .sink { statistics in
                    guard let statistics else { return }
                    Task {
                        self.streamStatistics = statistics
                    }
                }
                .store(in: &subscriptions)
        }
    }
}

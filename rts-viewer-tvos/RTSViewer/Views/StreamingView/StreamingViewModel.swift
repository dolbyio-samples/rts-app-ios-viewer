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
    private let playoutDelay: PlayoutDelay
    private let persistentSettings: PersistentSettingsProtocol
    private var layersEventsObservationDictionary: [SourceID: Task<Void, Never>] = [:]
    private var stateObservation: Task<Void, Never>?
    private var reconnectionTimer: Timer?
    private var isWebsocketConnected: Bool = false

    private var subscriptions: [AnyCancellable] = []
    private var projectedMids: Set<String> = []
    private let serialTasks = SerialTasks()

    enum ViewState: Equatable {
        case disconnected
        case streaming(source: StreamSource, playingAudio: Bool, playingVideo: Bool)
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
                case let .streaming(source: source, _, _):
                    select(videoQuality: .auto, for: source)
                default:
                    break
                }
            }
        }
    }
    @Published private(set) var selectedVideoQuality: VideoQuality = .auto
    @Published private(set) var projectedTimeStampForMids: [String: Double] = [:]
    @Published private(set) var streamStatistics: MCSubscriberStats?

    let subscriptionManager: SubscriptionManager
    let rendererRegistry: RendererRegistry

    init(
        streamName: String,
        accountID: String,
        subscriptionManager: SubscriptionManager = SubscriptionManager(),
        persistentSettings: PersistentSettingsProtocol = PersistentSettings(),
        playoutDelay: PlayoutDelay = PlayoutDelay(),
        rendererRegistry: RendererRegistry = RendererRegistry()
    ) {
        self.streamName = streamName
        self.accountID = accountID
        self.playoutDelay = playoutDelay
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
                try await subscriptionManager.subscribe(streamName: streamName, accountID: accountID, configuration: SubscriptionConfiguration(playoutDelay: MCForcePlayoutDelay(playoutDelay)))
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
                let renderer = self.rendererRegistry.sampleBufferRenderer(for: source)
                self.selectedVideoQuality = videoQuality
                switch videoQuality {
                case .auto:
                    try await source.videoTrack?.enable(renderer: renderer.underlyingRenderer, promote: true)
                case let .quality(underlyingLayer):
                    try await source.videoTrack?.enable(renderer: renderer.underlyingRenderer, layer: MCRTSRemoteVideoTrackLayer(layer: underlyingLayer), promote: true)
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
                            Self.logger.debug("🎰 Subscribed, has \(sources.count) sources")
                            // Pick the first source for viewing / listening
                            guard let firstSource = sources.first(where: { $0.videoTrack?.isActive == true || $0.audioTrack?.isActive == true }) else {
                                self.state = .streamNotPublished(
                                    title: LocalizedStringKey("stream.offline.title.label").toString(),
                                    subtitle: LocalizedStringKey("stream.offline.subtitle.label").toString(),
                                    source: nil
                                )
                                self.clearLayerInformation()
                                self.removeProjectedMidsAndTimeStamps()
                                return
                            }

                            Task(priority: .userInitiated) {
                                guard !Task.isCancelled else { return }

                                await self.observeLayerEvents(for: firstSource)
                            }

                            Task(priority: .high) {
                                guard !Task.isCancelled else {
                                    return
                                }

                                try await self.serialTasks.enqueue {
                                    switch await self.state {
                                    case let .streaming(source: currentSource, playingAudio: isPlayingAudio, playingVideo: isPlayingVideo):
                                        // No-action needed, already viewing stream
                                        await Self.logger.debug("🎰 Already viewing source \(currentSource.sourceId)")
                                        if !isPlayingAudio {
                                            if let audioTrack = firstSource.audioTrack, audioTrack.isActive {
                                                await Self.logger.debug("🎰 Picked source \(firstSource.sourceId) for audio")
                                                // Enable new audio track
                                                try await audioTrack.enable()
                                                await self.storeProjectedMid(for: audioTrack)
                                                await MainActor.run {
                                                    self.state = .streaming(source: firstSource, playingAudio: true, playingVideo: isPlayingVideo)
                                                }
                                            }
                                        }
                                        if !isPlayingVideo, let videoTrack = firstSource.videoTrack, videoTrack.isActive {
                                            let renderer = await MainActor.run {
                                                self.rendererRegistry.sampleBufferRenderer(for: firstSource)
                                            }
                                            try await videoTrack.enable(renderer: renderer.underlyingRenderer, promote: true)
                                            await self.storeProjectedMid(for: videoTrack)
                                            await Self.logger.debug("🎰 Picked source \(firstSource.sourceId) for video")
                                            await MainActor.run {
                                                self.state = .streaming(source: firstSource, playingAudio: isPlayingAudio, playingVideo: true)
                                            }
                                        }
                                    default:
                                        await Self.logger.debug("🎰 Picked source \(firstSource.sourceId)")

                                        let isPlayingVideo: Bool
                                        if let videoTrack = firstSource.videoTrack, videoTrack.isActive {
                                            let renderer = await MainActor.run {
                                                self.rendererRegistry.sampleBufferRenderer(for: firstSource)
                                            }
                                            try await videoTrack.enable(renderer: renderer.underlyingRenderer, promote: true)
                                            await self.storeProjectedMid(for: videoTrack)
                                            await Self.logger.debug("🎰 Picked source \(firstSource.sourceId) for video")
                                            isPlayingVideo = true
                                        } else {
                                            isPlayingVideo = false
                                        }

                                        let isPlayingAudio: Bool
                                        if let audioTrack = firstSource.audioTrack, audioTrack.isActive {
                                            await Self.logger.debug("🎰 Picked source \(firstSource.sourceId) for audio")
                                            // Enable new audio track
                                            try await audioTrack.enable()
                                            await self.storeProjectedMid(for: audioTrack)
                                            isPlayingAudio = true
                                        } else {
                                            isPlayingAudio = false
                                        }

                                        await MainActor.run {
                                            self.state = .streaming(
                                                source: firstSource,
                                                playingAudio: isPlayingAudio,
                                                playingVideo: isPlayingVideo
                                            )
                                        }
                                    }
                                }
                            }

                        case .disconnected:
                            Self.logger.debug("🎰 Disconnected")
                            guard !Task.isCancelled else { return }

                            self.state = .disconnected

                        case let .error(connectionError) where connectionError.status == 0:
                            Self.logger.debug("🎰 No internet connection")
                            guard !Task.isCancelled else { return }

                            if !self.isWebsocketConnected {
                                self.scheduleReconnection()
                            }

                            self.state = .noNetwork(
                                title: LocalizedStringKey("stream.network.disconnected.label").toString()
                            )

                        case let .error(connectionError):
                            Self.logger.debug("🎰 Connection error - \(connectionError.status), \(connectionError.reason)")
                            guard !Task.isCancelled else { return }

                            if !self.isWebsocketConnected {
                                self.scheduleReconnection()
                            }

                            self.state = .streamNotPublished(
                                title: LocalizedStringKey("stream.offline.title.label").toString(),
                                subtitle: LocalizedStringKey("stream.offline.subtitle.label").toString(),
                                source: nil
                            )
                        }
                    }
                }
                .store(in: &subscriptions)

            await self.subscriptionManager.$websocketState
                .receive(on: DispatchQueue.main)
                .sink { websocketState in
                    switch websocketState {
                    case .connected:
                        self.isWebsocketConnected = true
                    default:
                        break
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

private extension StreamingViewModel {

    func observeLayerEvents(for source: StreamSource) async {
        guard let videoTrack = source.videoTrack, layersEventsObservationDictionary[source.sourceId] == nil else {
            return
        }

        Self.logger.debug("♼ Registering layer events for \(source.sourceId)")
        let layerEventsObservationTask = Task {
            for await layerEvent in videoTrack.layers() {
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
        projectedTimeStampForMids.removeAll()
        projectedMids.removeAll()
    }

    func clearLayerInformation() {
        videoQualityList.removeAll()
        selectedVideoQuality = .auto
    }

    func scheduleReconnection() {
        Self.logger.debug("🎰 Schedule reconnection")
        self.reconnectionTimer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(subscribeToStream), userInfo: nil, repeats: false)
    }

    func observeStreamStatistics() {
        Task { [weak self] in
            guard let self else { return }
            for await statistics in await self.subscriptionManager.subscriber.stats() {
                self.storeProjectedTimeStamp(stats: statistics)
                self.streamStatistics = statistics
            }
        }
    }

    func storeProjectedTimeStamp(stats: MCSubscriberStats) {
        stats.trackStats.forEach {
            if projectedMids.contains($0.mid),
               projectedTimeStampForMids[$0.mid] == nil {
                projectedTimeStampForMids[$0.mid] = $0.timestamp
            }
        }
    }

    func storeProjectedMid(for track: MCRTSRemoteTrack) {
        guard let mid = track.currentMID else {
            return
        }
        projectedMids.insert(mid)
    }

    func removeProjectedMidsAndTimeStamps() {
        projectedMids.removeAll()
        projectedTimeStampForMids.removeAll()
    }
}

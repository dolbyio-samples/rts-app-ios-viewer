//
//  StreamingViewModel.swift
//

import Combine
import Foundation
import MillicastSDK
import os
import RTSComponentKit
import UIKit
import SwiftUI

@MainActor
final class StreamingViewModel: ObservableObject {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: StreamingViewModel.self)
    )

    private let persistentSettings: PersistentSettingsProtocol
    private var audioTrackActivityObservationDictionary: [SourceID: Task<Void, Never>] = [:]
    private var videoTrackActivityObservationDictionary: [SourceID: Task<Void, Never>] = [:]
    private var layerEventsObservationTask: Task<Void, Never>?

    private var subscriptions: [AnyCancellable] = []

    enum ViewState {
        case stopped
        case loading
        case pendingActivation(source: Source)
        case streaming(source: Source)
        case noNetwork(title: String)
        case streamNotPublished(title: String, subtitle: String, source: Source?)
        case otherError(message: String)
    }
    @Published private(set) var state: ViewState = .loading
    @Published private(set) var isLiveIndicatorEnabled: Bool {
        didSet {
            persistentSettings.liveIndicatorEnabled = isLiveIndicatorEnabled
        }
    }
    @Published private(set) var videoQualityList: [VideoQuality] = []
    @Published var selectedVideoQuality: VideoQuality = .auto

    let subscriptionManager: SubscriptionManager
    let rendererRegistry: RendererRegistry

    init(
        subscriptionManager: SubscriptionManager,
        persistentSettings: PersistentSettingsProtocol = PersistentSettings(),
        rendererRegistry: RendererRegistry = RendererRegistry()
    ) {
        self.subscriptionManager = subscriptionManager
        self.persistentSettings = persistentSettings
        self.rendererRegistry = rendererRegistry

        isLiveIndicatorEnabled = persistentSettings.liveIndicatorEnabled
        setupStateObservers()
    }

    func updateLiveIndicator(_ enabled: Bool) {
        isLiveIndicatorEnabled = enabled
    }

    // swiftlint: disable function_body_length
    private func setupStateObservers() {
        Task { [weak self] in
            guard let self = self else { return }

            await self.subscriptionManager.$state
                .sink { state in
                    Task {
                        switch state {
                        case let .subscribed(sources: sources):
                            Self.logger.debug("🎰 Subscribed, has \(sources.count) sources")

                            // MARK: Picking the source with empty sourceId or the first source for display
                            guard let source = sources.first(where: { $0.sourceId == .main }) ?? sources.first else {
                                return
                            }

                            Self.logger.debug("🎰 Picked source \(source.sourceId) for rendering")
                            if !self.rendererRegistry.hasRenderer(for: source) {
                                self.rendererRegistry.registerRenderer(renderer: .sampleBuffer(MCCMSampleBufferVideoRenderer()), for: source)
                            }
                            if !source.isVideoTrackActive {
                                self.observeTrackEvents(for: source)
                                self.observeLayerEvents(for: source)
                                let renderer = self.rendererRegistry.renderer(for: source)
                                try await source.videoTrack.enable(renderer: renderer.underlyingRenderer, promote: true)
                            }
                            await MainActor.run {
                                self.state = source.isVideoTrackActive ? .streaming(source: source) : .pendingActivation(source: source)
                            }

                        case .stopped:
                            Self.logger.debug("🎰 Stopped")
                            await MainActor.run {
                                self.state = .stopped
                            }

                        case .error(.connectError(status: 0, reason: _)):
                            Self.logger.debug("🎰 No internet connection")
                            await MainActor.run {
                                self.state = .noNetwork(
                                    title: LocalizedStringKey("stream.network.disconnected.label").toString()
                                )
                            }

                        case let .error(.connectError(status: status, reason: reason)):
                            Self.logger.debug("🎰 Connection error - \(status), \(reason)")
                            await MainActor.run {
                                self.state = .streamNotPublished(
                                    title: LocalizedStringKey("stream.offline.title.label").toString(),
                                    subtitle: LocalizedStringKey("stream.offline.subtitle.label").toString(),
                                    source: nil
                                )
                            }

                        case let .error(.signalingError(reason: reason)):
                            Self.logger.debug("🎰 Signaling error - \(reason)")
                            await MainActor.run {
                                self.state = .otherError(message: reason)
                            }
                        }
                    }
                }
                .store(in: &subscriptions)
        }
    }
    // swiftlint: enable function_body_length

    func stopSubscribe() async throws {
        _ = try await subscriptionManager.unSubscribe()
        removeAllObservations()
    }

    func videoViewDidAppear() async throws {
        switch state {
        case let .streaming(source: source):
            if !source.isAudioTrackActive, let audioTrack = source.audioTrack {
                try await audioTrack.enable()
            }
        default:
            Self.logger.debug("🎰 Invalid state when calling `videoViewDidAppear`")
        }
    }
}

// MARK: Track lifecycle events

extension StreamingViewModel {

    func observeTrackEvents(for source: Source) {
        Self.logger.debug("♼ Registering for track lifecycle events of \(source.sourceId)")

        Task { [weak self] in
            guard let self, let audioTrack = source.audioTrack else { return }

            var tasksToAwait: [Task<Void, Never>] = []

            if audioTrackActivityObservationDictionary[source.sourceId] == nil {
                Self.logger.debug("♼ Registering for audio track lifecycle events of \(source.sourceId)")
                let audioTrackActivityObservation = Task {
                    for await activityEvent in audioTrack.activity() {
                        switch activityEvent {
                        case .active:
                            Self.logger.debug("♼ Audio track for \(source.sourceId) is active")
                            self.audioTrackIsActive(for: source)

                        case .inactive:
                            Self.logger.debug("♼ Audio track for \(source.sourceId) is inactive")
                            self.audioTrackIsInactive(for: source)
                        }
                    }
                }
                audioTrackActivityObservationDictionary[source.sourceId] = audioTrackActivityObservation
                tasksToAwait.append(audioTrackActivityObservation)
            }

            if videoTrackActivityObservationDictionary[source.sourceId] == nil {
                Self.logger.debug("♼ Registering for video track lifecycle events of \(source.sourceId)")
                let videoTrackActivityObservation = Task {
                    for await activityEvent in source.videoTrack.activity() {
                        switch activityEvent {
                        case .active:
                            Self.logger.debug("♼ Video track for \(source.sourceId) is active")
                            self.videoTrackIsActive(for: source)

                        case .inactive:
                            Self.logger.debug("♼ Video track for \(source.sourceId) is inactive")
                            self.videoTrackIsActive(for: source)
                        }
                    }
                }
                videoTrackActivityObservationDictionary[source.sourceId] = videoTrackActivityObservation
                tasksToAwait.append(videoTrackActivityObservation)
            }

            await withTaskGroup(of: Void.self) { group in
                for task in tasksToAwait {
                    group.addTask {
                        await task.value
                    }
                }
            }
        }
    }

    func removeAllObservations() {
        audioTrackActivityObservationDictionary.forEach { (sourceId, _) in
            audioTrackActivityObservationDictionary[sourceId]?.cancel()
            audioTrackActivityObservationDictionary[sourceId] = nil
        }
        videoTrackActivityObservationDictionary.forEach { (sourceId, _) in
            videoTrackActivityObservationDictionary[sourceId]?.cancel()
            videoTrackActivityObservationDictionary[sourceId] = nil
        }
        subscriptions.removeAll()

        layerEventsObservationTask?.cancel()
        layerEventsObservationTask = nil
    }

    func audioTrackIsActive(for source: Source) {
        // No-op
    }

    func audioTrackIsInactive(for source: Source) {
        // No-op
    }

    func videoTrackIsActive(for source: Source) {
        switch state {
        case let .pendingActivation(source: sourcePendingActivation) where sourcePendingActivation.sourceId == source.sourceId:
            state = .streaming(source: source)
        case let .streamNotPublished(title: _, subtitle: _, source: .some(sourcePendingActivation)) where sourcePendingActivation.sourceId == source.sourceId:
            state = .streaming(source: source)
        default:
            // No-op
            break
        }
    }

    func videoTrackIsInactive(for source: Source) {
        switch state {
        case let .streaming(source: sourcePendingActivation) where sourcePendingActivation.sourceId == source.sourceId:
            state = .streamNotPublished(
                title: LocalizedStringKey("stream.offline.title.label").toString(),
                subtitle: LocalizedStringKey("stream.offline.subtitle.label").toString(),
                source: source
            )
        default:
            // No-op
            break
        }
    }
}

private extension StreamingViewModel {
    // swiftlint:disable function_body_length
    func observeLayerEvents(for source: Source) {
        Task { [weak self] in
            guard let self else { return }
            self.layerEventsObservationTask = Task {
                for await layerEvent in source.videoTrack.layers() {
                    var layersForSelection: [MCRTSRemoteTrackLayer] = []
                    // Simulcast active layers
                    let simulcastLayers = layerEvent.active.filter({ !$0.encodingId.isEmpty })
                    let svcLayers = layerEvent.active.filter({ $0.spatialLayerId != nil })
                    if !simulcastLayers.isEmpty {
                        // Select the max (best) temporal layer Id from a specific encodingId
                        let dictionaryOfLayersMatchingEncodingId = Dictionary(grouping: simulcastLayers, by: { $0.encodingId })
                        dictionaryOfLayersMatchingEncodingId.forEach { (_: String, layers: [MCRTSRemoteTrackLayer]) in
                            // Picking the layer matching the max temporal layer id - represents the layer with the best FPS
                            if let layerWithBestFrameRate = layers.first(where: { $0.temporalLayerId == $0.maxTemporalLayerId }) ?? layers.last {
                                layersForSelection.append(layerWithBestFrameRate)
                            }
                        }
                    }
                    // Using SVC layer selection logic
                    else {
                        let dictionaryOfLayersMatchingSpatialLayerId = Dictionary(grouping: svcLayers, by: { $0.spatialLayerId! })
                        dictionaryOfLayersMatchingSpatialLayerId.forEach { (_: NSNumber, layers: [MCRTSRemoteTrackLayer]) in
                            // Picking the layer matching the max temporal layer id - represents the layer with the best FPS
                            if let layerWithBestFrameRate = layers.first(where: { $0.spatialLayerId == $0.maxSpatialLayerId }) ?? layers.last {
                                layersForSelection.append(layerWithBestFrameRate)
                            }
                        }
                    }

                    layersForSelection = layersForSelection
                        .sorted { lhs, rhs in
                          if let rhsLayerResolution = rhs.resolution, let lhsLayerResolution = lhs.resolution {
                                return rhsLayerResolution.width < lhsLayerResolution.width || rhsLayerResolution.height < rhsLayerResolution.height
                            } else {
                                return rhs.bitrate < lhs.bitrate
                            }
                        }
                    let topSimulcastLayers = Array(layersForSelection.prefix(3))
                    switch topSimulcastLayers.count {
                    case 2:
                        self.videoQualityList = [
                            .auto,
                            .high(topSimulcastLayers[0]),
                            .low(topSimulcastLayers[1])
                        ]
                    case 3...Int.max:
                        self.videoQualityList = [
                            .auto,
                            .high(topSimulcastLayers[0]),
                            .medium(topSimulcastLayers[1]),
                            .low(topSimulcastLayers[2])
                        ]
                    default:
                        self.videoQualityList = [.auto]
                    }
                }
            }

            await self.layerEventsObservationTask?.value
        }
    }
    // swiftlint:enable function_body_length
}

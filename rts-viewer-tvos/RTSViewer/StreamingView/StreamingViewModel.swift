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

    private let persistentSettings: PersistentSettingsProtocol
    private var audioTrackActivityObservationDictionary: [SourceID: Task<Void, Never>] = [:]
    private var videoTrackActivityObservationDictionary: [SourceID: Task<Void, Never>] = [:]
    private var layerEventsObservationTask: Task<Void, Never>?

    private var subscriptions: [AnyCancellable] = []
    private let trackActiveStateUpdateSubject: CurrentValueSubject<Void, Never> = CurrentValueSubject(())

    enum ViewState {
        case stopped
        case loading
        case streaming(source: StreamSource)
        case noNetwork(title: String)
        case streamNotPublished(title: String, subtitle: String, source: StreamSource?)
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

            await self.subscriptionManager.$state.combineLatest(trackActiveStateUpdateSubject)
                .sink { state, _ in
                    Task {
                        switch state {
                        case let .subscribed(sources: sources):
                            Self.logger.debug("🎰 Subscribed, has \(sources.count) sources")

                            // MARK: Picking the source with empty sourceId or the first source for display
                            let activeSources = sources.filter { $0.videoTrack.isActive }
                            guard let source = activeSources.first(where: { $0.sourceId == .main }) ?? sources.first else {
                                self.state = .streamNotPublished(
                                    title: LocalizedStringKey("stream.offline.title.label").toString(),
                                    subtitle: LocalizedStringKey("stream.offline.subtitle.label").toString(),
                                    source: nil
                                )
                                return
                            }

                            Self.logger.debug("🎰 Picked source \(source.sourceId) for rendering")

                            self.observeTrackEvents(for: source)
                            self.observeLayerEvents(for: source)
                            let renderer = self.rendererRegistry.acceleratedRenderer(for: source)
                            try await source.videoTrack.enable(renderer: renderer.underlyingRenderer, promote: true)
                            await MainActor.run {
                                self.state = .streaming(source: source)
                            }

                        case .disconnected:
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
                        case .stopped:
                            Self.logger.debug("🎰 Stream stopped")
                            await MainActor.run {
                                self.state = .streamNotPublished(
                                    title: LocalizedStringKey("stream.offline.title.label").toString(),
                                    subtitle: LocalizedStringKey("stream.offline.subtitle.label").toString(),
                                    source: nil
                                )
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
        Self.logger.debug("🎰 Unsubscribed successfully")
    }

    func videoViewDidAppear() async throws {
        switch state {
        case let .streaming(source: source):
            if let audioTrack = source.audioTrack {
                try await audioTrack.enable()
            }
        default:
            Self.logger.debug("🎰 Invalid state when calling `videoViewDidAppear`")
        }
    }
}

// MARK: Track lifecycle events

extension StreamingViewModel {

    func observeTrackEvents(for source: StreamSource) {
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
                            self.trackActiveStateUpdateSubject.send()

                        case .inactive:
                            Self.logger.debug("♼ Video track for \(source.sourceId) is inactive")
                            self.trackActiveStateUpdateSubject.send()
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

    func audioTrackIsActive(for source: StreamSource) {
        // No-op
    }

    func audioTrackIsInactive(for source: StreamSource) {
        // No-op
    }
}

private extension StreamingViewModel {
    func observeLayerEvents(for source: StreamSource) {
        Task { [weak self] in
            guard let self else { return }
            self.layerEventsObservationTask = Task {
                for await layerEvent in source.videoTrack.layers() {
                    let videoQualities = layerEvent.layers()
                        .map(VideoQuality.init)
                        .reduce([.auto]) { $0 + [$1] }
                    self.videoQualityList = videoQualities
                }
            }

            await self.layerEventsObservationTask?.value
        }
    }
}

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

    private var subscriptions: [AnyCancellable] = []

    enum ViewState {
        case disconnected
        case loading
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
    @Published private(set) var videoQualityList: [VideoQuality] = []
    @Published var selectedVideoQuality: VideoQuality = .auto

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
    }

    func subscribeToStream() {
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

    // swiftlint: disable function_body_length
    private func setupStateObservers() async {
        stateObservation = Task(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }

            await self.subscriptionManager.$state
                .receive(on: DispatchQueue.main)
                .sink { state in
                    Task(priority: .high) {
                        switch state {
                        case let .subscribed(sources: sources):
                            // FIXME: `MCRTSRemoteTrack.isActive` returns true even after receiving an inactive event.
                            // Update the filter logic to .filter { $0.videoTrack.isActive }
                            let activeVideoSources = sources.filter { $0.isVideoActive }
                            Self.logger.debug("🎰 Subscribed, has \(activeVideoSources.count) active video sources")
                            guard let videoSource = activeVideoSources.first(where: { $0.sourceId == .main }) ?? activeVideoSources.first else {
                                self.state = .streamNotPublished(
                                    title: LocalizedStringKey("stream.offline.title.label").toString(),
                                    subtitle: LocalizedStringKey("stream.offline.subtitle.label").toString(),
                                    source: nil
                                )
                                return
                            }

                            Self.logger.debug("🎰 Picked source \(videoSource.sourceId) for rendering")

                            // FIXME: `MCRTSRemoteTrack.isActive` returns true even after receiving an inactive event.
                            // Update the filter logic to .filter { $0.audioTrack?.isActive == true }
                            let activeAudioSources = sources.filter { $0.isVideoActive }

                            Task(priority: .userInitiated) {
                                await self.observeLayerEvents(for: videoSource)
                            }

                            Task(priority: .high) {
                                let renderer = self.rendererRegistry.acceleratedRenderer(for: videoSource)
                                try await videoSource.videoTrack.enable(renderer: renderer.underlyingRenderer, promote: true)

                                if let audioTrack = videoSource.audioTrack, !activeAudioSources.contains(videoSource) {
                                    Self.logger.debug("🎰 Picked source \(videoSource.sourceId) for rendering")
                                    // Enable new audio track
                                    try await audioTrack.enable()
                                }

                                await MainActor.run {
                                    self.state = .streaming(source: videoSource)
                                }
                            }

                        case .disconnected:
                            Self.logger.debug("🎰 Disconnected")
                            self.state = .disconnected

                        case .error(.connectError(status: 0, reason: _)):
                            Self.logger.debug("🎰 No internet connection")
                            self.state = .noNetwork(
                                title: LocalizedStringKey("stream.network.disconnected.label").toString()
                            )

                        case let .error(.connectError(status: status, reason: reason)):
                            Self.logger.debug("🎰 Connection error - \(status), \(reason)")
                            self.state = .streamNotPublished(
                                title: LocalizedStringKey("stream.offline.title.label").toString(),
                                subtitle: LocalizedStringKey("stream.offline.subtitle.label").toString(),
                                source: nil
                            )

                        case let .error(.signalingError(reason: reason)):
                            Self.logger.debug("🎰 Signaling error - \(reason)")
                            self.state = .otherError(message: reason)
                        case .stopped:
                            Self.logger.debug("🎰 Stream stopped")
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
    // swiftlint: enable function_body_length

    func stopSubscribe() {
        Task(priority: .userInitiated) {
            do {
                Self.logger.debug("🎰 Subscribe to stream with \(self.streamName), \(self.accountID)")
                removeAllObservations()
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

    // swiftlint:disable cyclomatic_complexity function_body_length
    func observeLayerEvents(for source: StreamSource) async {
        var tasks: [Task<Void, Never>] = []
        if layersEventsObservationDictionary[source.sourceId] == nil {
            Self.logger.debug("♼ Registering layer events for \(source.sourceId)")
            let layerEventsObservationTask = Task {
                for await layerEvent in source.videoTrack.layers() {
                    let videoQualities = layerEvent.layers()
                        .map(VideoQuality.init)
                        .reduce([.auto]) { $0 + [$1] }
                    self.videoQualityList = videoQualities
                }
            }

            layersEventsObservationDictionary[source.sourceId] = layerEventsObservationTask
            tasks.append(layerEventsObservationTask)
        }

        _ = await withTaskGroup(of: Void.self) { group in
            for task in tasks {
                group.addTask {
                    await task.value
                }
            }
        }
    }
    // swiftlint:enable cyclomatic_complexity function_body_length

    func removeAllObservations() {
        subscriptions.removeAll()
        layersEventsObservationDictionary.forEach { (sourceId, _) in
            layersEventsObservationDictionary[sourceId]?.cancel()
            layersEventsObservationDictionary[sourceId] = nil
        }
        stateObservation?.cancel()
    }
}

//
//  VideoTracksManager.swift
//

import Combine
import Foundation
import MillicastSDK
import os
import RTSCore

final actor VideoTracksManager {
    typealias ViewID = String

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: VideoTracksManager.self)
    )

    private struct VideoQualityAndLayerPair: Equatable {
        let videoQuality: VideoQuality
        let layer: MCRTSRemoteTrackLayer?

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.videoQuality == rhs.videoQuality && lhs.layer?.encodingId == rhs.layer?.encodingId
        }
    }

    private var sourceToTasks: [SourceID: SerialTasks] = [:]

    // View's rendering a source
    private var sourceToActiveViewsMapping: [SourceID: [ViewID]] = [:]

    // View's to requested video quality
    private var viewToRequestedVideoQualityMapping: [ViewID: VideoQuality] = [:]

    // Selected layer information
    private var sourceToSelectedVideoQualityAndLayerMapping: [SourceID: VideoQualityAndLayerPair] = [:] {
        didSet {
            let sourceToVideoQuality = sourceToSelectedVideoQualityAndLayerMapping
                .mapValues {
                    $0.videoQuality
                }
            videoQualitySubject.send(sourceToVideoQuality)
        }
    }

    private let subscriptionManager: SubscriptionManager
    private var layerEventsObservationDictionary: [SourceID: Task<Void, Never>] = [:]
    private let videoQualitySubject: CurrentValueSubject<[SourceID: VideoQuality], Never> = CurrentValueSubject([:])
    private let layersSubject: CurrentValueSubject<[SourceID: [MCRTSRemoteTrackLayer]], Never> = CurrentValueSubject([:])

    let rendererRegistry: RendererRegistry
    lazy var selectedVideoQualityPublisher = videoQualitySubject.eraseToAnyPublisher()
    lazy var layersPublisher = layersSubject.eraseToAnyPublisher()
    private(set) var projectedTimeStampForMids: [String: Double] = [:]
    private(set) var sourceToSimulcastLayersMapping: [SourceID: [MCRTSRemoteTrackLayer]] = [:] {
        didSet {
            layersSubject.send(sourceToSimulcastLayersMapping)
        }
    }
    private var subscriptions: Set<AnyCancellable> = []
    private var projectedMids: Set<String> = []

    init(subscriptionManager: SubscriptionManager, rendererRegistry: RendererRegistry = RendererRegistry()) {
        self.rendererRegistry = rendererRegistry
        self.subscriptionManager = subscriptionManager
        observeStats()
    }

    nonisolated private func observeStats() {
        Task { [weak self] in
            guard let self else { return }
            let cancellable = await self.subscriptionManager.$streamStatistics
                .receive(on: DispatchQueue.main)
                .sink { [weak self] statistics in
                    guard let self, let stats = statistics else { return }
                    Task {
                        await self.saveProjectedTimeStamp(stats: stats)
                    }
                }
            await self.store(cancellable: cancellable)
        }
    }

    func observeLayerUpdates(for source: StreamSource) {
        Task { [weak self] in
            guard
                let self,
                await self.layerEventsObservationDictionary[source.sourceId] == nil
            else {
                return
            }
            let layerEventsObservationTask = Task {
                for await layerEvent in source.videoTrack.layers() {
                    let simulcastLayers = layerEvent.layers()
                    await self.addSimulcastLayers(simulcastLayers, for: source)
                }
            }

            Self.logger.debug("♼ Registering layers events of \(source.sourceId)")
            await self.addLayerEventsObservationTask(layerEventsObservationTask, for: source)
            await layerEventsObservationTask.value
        }
    }

    func reset() {
        sourceToTasks.removeAll()
        layerEventsObservationDictionary.removeAll()
        sourceToActiveViewsMapping.removeAll()
        viewToRequestedVideoQualityMapping.removeAll()
        sourceToSimulcastLayersMapping.removeAll()
        sourceToSelectedVideoQualityAndLayerMapping.removeAll()
        projectedMids.removeAll()
        projectedTimeStampForMids.removeAll()
    }

    func enableTrack(for source: StreamSource, with preferredVideoQuality: VideoQuality, on view: ViewID) async {
        let sourceId = source.sourceId
        Self.logger.debug("♼ Request to enable video track for source \(sourceId) with preferredVideoQuality \(preferredVideoQuality.displayText) from view \(view.description)")

        // If the view has already requested the same video quality before? if yes, exit
        guard viewToRequestedVideoQualityMapping[view] != preferredVideoQuality else {
            Self.logger.debug("♼ Exiting - View already presented for source \(sourceId) with preferredVideoQuality \(preferredVideoQuality.displayText)")
            return
        }

        let activeViewsForSource = sourceToActiveViewsMapping[sourceId] ?? []
        // Calculate the video quality to project from the requested list
        // Note: Only one layer can be selected for a source at a given time
        var videoQualitiesRequestedForSource = activeViewsForSource
            .compactMap { viewToRequestedVideoQualityMapping[$0] }
        videoQualitiesRequestedForSource.append(preferredVideoQuality)
        let bestVideoQualityFromTheList = videoQualitiesRequestedForSource.bestVideoQualityFromTheRequestedList
        let simulcastLayers = sourceToSimulcastLayersMapping[sourceId]
        let layerToSelect = simulcastLayers.map { $0.matching(quality: bestVideoQualityFromTheList) } ?? nil
        Self.logger.debug("♼ Source \(sourceId) has \(simulcastLayers?.count ?? 0) simulcast layers")

        let videoQualityToSelect: VideoQuality = layerToSelect == nil ? .auto : bestVideoQualityFromTheList
        let newVideoQualityAndLayerPair = VideoQualityAndLayerPair(videoQuality: videoQualityToSelect, layer: layerToSelect)

        Self.logger.debug("♼ Add active view \(view.description) for source \(sourceId)")
        // Update view's requested video quality
        viewToRequestedVideoQualityMapping[view] = preferredVideoQuality

        // Add new view to the list of active views for that source
        if var views = sourceToActiveViewsMapping[sourceId] {
            views.append(view)
            sourceToActiveViewsMapping[source.sourceId] = views
        } else {
            sourceToActiveViewsMapping[source.sourceId] = [view]
        }

        do {
            if let layerToSelect {
                Self.logger.debug("♼ Simulcast layer - \(layerToSelect) for source \(sourceId)")
                Self.logger.debug("♼ Selecting videoquality \(videoQualityToSelect.displayText) for source \(sourceId) on view \(view)")
                sourceToSelectedVideoQualityAndLayerMapping[sourceId] = newVideoQualityAndLayerPair

                try await queueEnableTrack(for: source, layer: MCRTSRemoteVideoTrackLayer(layer: layerToSelect))
            } else {
                Self.logger.debug("♼ No simulcast layer for source \(sourceId) matching \(bestVideoQualityFromTheList.displayText)")
                Self.logger.debug("♼ Selecting videoquality 'Auto' for source \(sourceId) on view \(view)")
                sourceToSelectedVideoQualityAndLayerMapping[sourceId] = newVideoQualityAndLayerPair

                try await queueEnableTrack(for: source)
            }
        } catch {
            Self.logger.debug("♼🛑 Enabling video track threw error \(error.localizedDescription)")
        }
    }

    func disableTrack(for source: StreamSource, on view: ViewID) async {
        let sourceId = source.sourceId
        Self.logger.debug("♼ Request to disable video track for source \(sourceId) on view \(view.description)")
        // Remove view from the list of active views for that source
        guard var activeViews = sourceToActiveViewsMapping[sourceId],
            activeViews.contains(where: { $0 == view })
        else {
            Self.logger.debug("♼ \(view.description) is not in the list of active views, returning")
            return
        }
        Self.logger.debug("♼ Remove view \(view.description) for source \(sourceId)")
        activeViews.removeAll(where: { $0 == view })
        sourceToActiveViewsMapping[source.sourceId] = !activeViews.isEmpty ? activeViews : nil

        // Remove view from View to requested video quality mapping
        viewToRequestedVideoQualityMapping[view] = nil

        if let activeViews = sourceToActiveViewsMapping[sourceId] {
            // Calculate the video quality to project from the requested list
            // Note: Only one projection can exist for a source at a given time
            let videoQualitiesRequestedForSource = activeViews.compactMap { viewToRequestedVideoQualityMapping[$0] }
            let bestVideoQualityFromRequested = videoQualitiesRequestedForSource.bestVideoQualityFromTheRequestedList
            let simulcastLayers = sourceToSimulcastLayersMapping[sourceId]
            let layerToSelect = simulcastLayers.map { $0.matching(quality: bestVideoQualityFromRequested) } ?? nil

            let selectedVideoQuality: VideoQuality = layerToSelect == nil ? .auto : bestVideoQualityFromRequested
            let newVideoQualityAndLayerPair = VideoQualityAndLayerPair(videoQuality: selectedVideoQuality, layer: layerToSelect)

            do {
                if let layerToSelect {
                    Self.logger.debug("♼ Has simulcast layer - \(layerToSelect) for source \(sourceId)")
                    Self.logger.debug("♼ Selecting videoquality \(selectedVideoQuality.displayText) for source \(sourceId); active view \(activeViews)")
                    sourceToSelectedVideoQualityAndLayerMapping[sourceId] = newVideoQualityAndLayerPair
                    try await queueEnableTrack(for: source, layer: MCRTSRemoteVideoTrackLayer(layer: layerToSelect))
                } else {
                    Self.logger.debug("♼ No simulcast layer for source \(sourceId) matching \(bestVideoQualityFromRequested.displayText)")
                    Self.logger.debug("♼ Selecting videoquality 'Auto' for source \(sourceId); active view \(activeViews)")
                    sourceToSelectedVideoQualityAndLayerMapping[sourceId] = newVideoQualityAndLayerPair
                    try await queueEnableTrack(for: source)
                }
            } catch {
                Self.logger.debug("♼🛑 Enabling video track threw error \(error.localizedDescription)")
            }
        } else {
            do {
                Self.logger.debug("♼ Disable video track for source \(sourceId) as there are no active views")

                // Remove selected Video quality for source
                sourceToSelectedVideoQualityAndLayerMapping[sourceId] = nil

                removeAllStoredData(for: source)

                try await queueDisableTrack(for: source)
            } catch {
                Self.logger.debug("♼🛑 Disabling video track threw error \(error.localizedDescription)")
            }
        }
    }

    func queueEnableTrack(for source: StreamSource, layer: MCRTSRemoteVideoTrackLayer? = nil) async throws {
        if self.sourceToTasks[source.sourceId] == nil {
            self.sourceToTasks[source.sourceId] = SerialTasks()
        }
        guard let serialTasks = sourceToTasks[source.sourceId],
              source.videoTrack.isActive
        else {
            return
        }

        let renderer = rendererRegistry.sampleBufferRenderer(for: source).underlyingRenderer
        try await serialTasks.enqueue { [weak self] in
            Self.logger.debug("♼ Queue: Enabling track for source \(source.sourceId) on renderer \(ObjectIdentifier(renderer).debugDescription)")
            guard
                let self,
                !Task.isCancelled,
                source.videoTrack.isActive
            else {
                return
            }
            if let layer {
                try await source.videoTrack.enable(renderer: renderer, layer: layer)
            } else {
                try await source.videoTrack.enable(renderer: renderer)
            }
            // Store mid
            if let mid = source.videoTrack.currentMID {
                await self.store(mid: mid)
            }
            Self.logger.debug("♼ Queue: Finished enabling track for source \(source.sourceId) on renderer \(ObjectIdentifier(renderer).debugDescription)")
        }
    }

    func queueDisableTrack(for source: StreamSource) async throws {
        guard let serialTasks = sourceToTasks[source.sourceId] else { return }
        try await serialTasks.enqueue {
            guard !Task.isCancelled, source.videoTrack.isActive else { return }
            Self.logger.debug("♼ Queue: Disabling track for source \(source.sourceId)")
            try await source.videoTrack.disable()
            // Remove mid
            if let mid = source.videoTrack.currentMID {
                await self.remove(mid: mid)
            }
            Self.logger.debug("♼ Queue: Finished disabling track for source \(source.sourceId)")
        }
    }
}

// MARK: Helper functions

private extension VideoTracksManager {
    func store(cancellable: AnyCancellable) {
        subscriptions.insert(cancellable)
    }

    func store(mid: String) {
        projectedMids.insert(mid)
    }

    func remove(mid: String) {
        projectedMids.remove(mid)
        projectedTimeStampForMids.removeValue(forKey: mid)
    }

    func saveProjectedTimeStamp(stats: StreamStatistics) {
        stats.videoStatsInboundRtpList.forEach {
            if let mid = $0.mid, projectedMids.contains(mid),
               projectedTimeStampForMids[mid] == nil {
                projectedTimeStampForMids[mid] = $0.timestamp
            }
        }
    }

    func addSimulcastLayers(_ layers: [MCRTSRemoteTrackLayer], for source: StreamSource) async {
        sourceToSimulcastLayersMapping[source.sourceId] = layers
        Self.logger.debug("♼ Add layers \(layers.count) for \(source.sourceId)")
        let sourceId = source.sourceId

        // Choose any active view to reenable the track
        guard let activeViews = sourceToActiveViewsMapping[sourceId],
              let anyActiveView = activeViews.first
        else {
            Self.logger.debug("♼ No active views for \(source.sourceId)")
            return
        }

        // Calculate the video quality to project from the requested list
        // Note: Only one projection can exist for a source at a given time
        let videoQualitiesRequestedForSource = activeViews
            .compactMap { viewToRequestedVideoQualityMapping[$0] }
        let bestVideoQualityFromRequested = videoQualitiesRequestedForSource.bestVideoQualityFromTheRequestedList
        let layerToSelect = layers.matching(quality: bestVideoQualityFromRequested)

        let selectedVideoQuality: VideoQuality = layerToSelect == nil ? .auto : bestVideoQualityFromRequested
        let newVideoQualityAndLayerPair = VideoQualityAndLayerPair(videoQuality: selectedVideoQuality, layer: layerToSelect)

        let currentVideoQualityAndLayerPair = sourceToSelectedVideoQualityAndLayerMapping[source.sourceId]
        guard newVideoQualityAndLayerPair != currentVideoQualityAndLayerPair else {
            // Currently selected video quality matches the newly calculated one, no action needed
            Self.logger.debug("♼ Exiting - Currently selected videoquality \(selectedVideoQuality.displayText) for source \(sourceId) is already up to date")
            return
        }

        do {
            if let layerToSelect {
                Self.logger.debug("♼ Has simulcast layer - \(layerToSelect) for source \(sourceId)")
                Self.logger.debug("♼ Selecting videoquality \(selectedVideoQuality.displayText) for source \(sourceId) on view \(anyActiveView)")
                sourceToSelectedVideoQualityAndLayerMapping[sourceId] = newVideoQualityAndLayerPair

                try await queueEnableTrack(for: source, layer: MCRTSRemoteVideoTrackLayer(layer: layerToSelect))
            } else {
                Self.logger.debug("♼ No simulcast layer for source \(sourceId) matching \(bestVideoQualityFromRequested.displayText)")
                Self.logger.debug("♼ Selecting videoquality 'Auto' for source \(sourceId) on view \(anyActiveView)")
                sourceToSelectedVideoQualityAndLayerMapping[sourceId] = newVideoQualityAndLayerPair

                try await queueEnableTrack(for: source)
            }
        } catch {
            Self.logger.debug("♼🛑 Enabling video track threw error \(error.localizedDescription)")
        }
    }

    func removeAllStoredData(for source: StreamSource) {
        let sourceId = source.sourceId
        let activeViews = sourceToActiveViewsMapping[sourceId]

        activeViews?.forEach { viewToRequestedVideoQualityMapping[$0] = nil }
        sourceToSimulcastLayersMapping[sourceId] = nil
        sourceToActiveViewsMapping[sourceId] = nil
    }
}

// MARK: Helpers to manage `Event` Observations

private extension VideoTracksManager {
    func addLayerEventsObservationTask(_ task: Task<Void, Never>, for source: StreamSource) {
        layerEventsObservationDictionary[source.sourceId] = task
    }
}

private extension Array where Self.Element == VideoQuality {
    var bestVideoQualityFromTheRequestedList: VideoQuality {
        sorted(by: >).first ?? .auto
    }
}

private extension Array where Self.Element == MCRTSRemoteTrackLayer {
    func matching(quality: VideoQuality) -> MCRTSRemoteTrackLayer? {
        return switch quality {
        case .auto: nil
        case .high: first
        case .medium: middle
        case .low: last
        }
    }
}

private extension Array {
    var middle: Element? {
        guard count != 0 else { return nil }
        let middleIndex = (count > 1 ? count - 1 : count) / 2
        return self[middleIndex]
    }
}

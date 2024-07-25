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

    // View's rendering a source
    private var sourceToActiveViewsMapping: [SourceID: [ViewID]] = [:]

    // View's to requested video quality
    private var viewToRequestedVideoQualityMapping: [ViewID: VideoQuality] = [:]

    // Layer information
    private var sourceToSimulcastLayersMapping: [SourceID: [MCRTSRemoteTrackLayer]] = [:]
    private var sourceToSelectedVideoQualityAndLayerMapping: [SourceID: VideoQualityAndLayerPair] = [:] {
        didSet {
            let sourceToVideoQuality = self.sourceToSelectedVideoQualityAndLayerMapping
                .mapValues {
                    $0.videoQuality
                }
            self.videoQualitySubject.send(sourceToVideoQuality)
        }
    }

    private var layerEventsObservationDictionary: [SourceID: Task<Void, Never>] = [:]
    private var sourceToTasks: [SourceID: SerialTasks] = [:]
    private let videoQualitySubject: CurrentValueSubject<[SourceID: VideoQuality], Never> = CurrentValueSubject([:])
    let rendererRegistry: RendererRegistry
    lazy var selectedVideoQualityPublisher = videoQualitySubject.eraseToAnyPublisher()
    @Published var sourcedTargetBitrates: [SourceID: Int?] = [:]

    init(rendererRegistry: RendererRegistry = RendererRegistry()) {
        self.rendererRegistry = rendererRegistry
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
        self.sourceToTasks.removeAll()
        self.layerEventsObservationDictionary.removeAll()
        self.sourceToActiveViewsMapping.removeAll()
        self.viewToRequestedVideoQualityMapping.removeAll()
        self.sourceToSimulcastLayersMapping.removeAll()
        self.sourceToSelectedVideoQualityAndLayerMapping.removeAll()
    }

    func enableTrack(for source: StreamSource, with preferredVideoQuality: VideoQuality, on view: ViewID) async {
        let sourceId = source.sourceId
        Self.logger.debug("♼ Request to enable video track for source \(sourceId) with preferredVideoQuality \(preferredVideoQuality.displayText) from view \(view.description)")

        // If the view has already requested the same video quality before? if yes, exit
        guard self.viewToRequestedVideoQualityMapping[view] != preferredVideoQuality else {
            Self.logger.debug("♼ Exiting - View already presented for source \(sourceId) with preferredVideoQuality \(preferredVideoQuality.displayText)")
            return
        }

        let activeViewsForSource = self.sourceToActiveViewsMapping[sourceId] ?? []
        // Calculate the video quality to project from the requested list
        // Note: Only one layer can be selected for a source at a given time
        var videoQualitiesRequestedForSource = activeViewsForSource
            .compactMap { self.viewToRequestedVideoQualityMapping[$0] }
        videoQualitiesRequestedForSource.append(preferredVideoQuality)
        let bestVideoQualityFromTheList = videoQualitiesRequestedForSource.bestVideoQualityFromTheRequestedList
        let simulcastLayers = self.sourceToSimulcastLayersMapping[sourceId]
        let layerToSelect = simulcastLayers.map { $0.matching(quality: bestVideoQualityFromTheList) } ?? nil
        Self.logger.debug("♼ Source \(sourceId) has \(simulcastLayers?.count ?? 0) simulcast layers")

        let videoQualityToSelect: VideoQuality = layerToSelect == nil ? .auto : bestVideoQualityFromTheList
        let newVideoQualityAndLayerPair = VideoQualityAndLayerPair(videoQuality: videoQualityToSelect, layer: layerToSelect)

        Self.logger.debug("♼ Add active view \(view.description) for source \(sourceId)")
        // Update view's requested video quality
        self.viewToRequestedVideoQualityMapping[view] = preferredVideoQuality

        // Add new view to the list of active views for that source
        if var views = sourceToActiveViewsMapping[sourceId] {
            views.append(view)
            self.sourceToActiveViewsMapping[source.sourceId] = views
        } else {
            self.sourceToActiveViewsMapping[source.sourceId] = [view]
        }

        do {
            if let layerToSelect {
                Self.logger.debug("♼ Simulcast layer - \(layerToSelect) for source \(sourceId)")
                Self.logger.debug("♼ Selecting videoquality \(videoQualityToSelect.displayText) for source \(sourceId) on view \(view)")
                self.sourceToSelectedVideoQualityAndLayerMapping[sourceId] = newVideoQualityAndLayerPair

                try await self.queueEnableTrack(for: source, layer: MCRTSRemoteVideoTrackLayer(layer: layerToSelect))
            } else {
                Self.logger.debug("♼ No simulcast layer for source \(sourceId) matching \(bestVideoQualityFromTheList.displayText)")
                Self.logger.debug("♼ Selecting videoquality 'Auto' for source \(sourceId) on view \(view)")
                self.sourceToSelectedVideoQualityAndLayerMapping[sourceId] = newVideoQualityAndLayerPair

                try await self.queueEnableTrack(for: source)
            }
        } catch {
            Self.logger.debug("♼🛑 Enabling video track threw error \(error.localizedDescription)")
        }
    }

    func disableTrack(for source: StreamSource, on view: ViewID) async {
        let sourceId = source.sourceId
        Self.logger.debug("♼ Request to disable video track for source \(sourceId) on view \(view.description)")
        Self.logger.debug("♼ Remove view \(view.description) for source \(sourceId)")
        // Remove view from the list of active views for that source
        if var activeViews = sourceToActiveViewsMapping[sourceId],
           activeViews.contains(where: { $0 == view }) {
            activeViews.removeAll(where: { $0 == view })
            self.sourceToActiveViewsMapping[source.sourceId] = !activeViews.isEmpty ? activeViews : nil
        }

        // Remove view from View to requested video quality mapping
        self.viewToRequestedVideoQualityMapping[view] = nil

        if let activeViews = sourceToActiveViewsMapping[sourceId] {
            // Calculate the video quality to project from the requested list
            // Note: Only one projection can exist for a source at a given time
            let videoQualitiesRequestedForSource = activeViews.compactMap { self.viewToRequestedVideoQualityMapping[$0] }
            let bestVideoQualityFromRequested = videoQualitiesRequestedForSource.bestVideoQualityFromTheRequestedList
            let simulcastLayers = self.sourceToSimulcastLayersMapping[sourceId]
            let layerToSelect = simulcastLayers.map { $0.matching(quality: bestVideoQualityFromRequested) } ?? nil

            let selectedVideoQuality: VideoQuality = layerToSelect == nil ? .auto : bestVideoQualityFromRequested
            let newVideoQualityAndLayerPair = VideoQualityAndLayerPair(videoQuality: selectedVideoQuality, layer: layerToSelect)

            do {
                if let layerToSelect {
                    Self.logger.debug("♼ Has simulcast layer - \(layerToSelect) for source \(sourceId)")
                    Self.logger.debug("♼ Selecting videoquality \(selectedVideoQuality.displayText) for source \(sourceId); active view \(activeViews)")
                    self.sourceToSelectedVideoQualityAndLayerMapping[sourceId] = newVideoQualityAndLayerPair
                    try await self.queueEnableTrack(for: source, layer: MCRTSRemoteVideoTrackLayer(layer: layerToSelect))
                } else {
                    Self.logger.debug("♼ No simulcast layer for source \(sourceId) matching \(bestVideoQualityFromRequested.displayText)")
                    Self.logger.debug("♼ Selecting videoquality 'Auto' for source \(sourceId); active view \(activeViews)")
                    self.sourceToSelectedVideoQualityAndLayerMapping[sourceId] = newVideoQualityAndLayerPair
                    try await self.queueEnableTrack(for: source)
                }
            } catch {
                Self.logger.debug("♼🛑 Enabling video track threw error \(error.localizedDescription)")
            }
        } else {
            do {
                Self.logger.debug("♼ Disable video track for source \(sourceId) as there are no active views")

                // Remove selected Video quality for source
                self.sourceToSelectedVideoQualityAndLayerMapping[sourceId] = nil

                removeAllStoredData(for: source)

                try await self.queueDisableTrack(for: source)
            } catch {
                Self.logger.debug("♼🛑 Disabling video track threw error \(error.localizedDescription)")
            }
        }
    }

    func queueEnableTrack(for source: StreamSource, layer: MCRTSRemoteVideoTrackLayer? = nil) async throws {
        if self.sourceToTasks[source.sourceId] == nil {
            self.sourceToTasks[source.sourceId] = SerialTasks()
        }

        let renderer = self.rendererRegistry.sampleBufferRenderer(for: source).underlyingRenderer
        guard let serialTasks = sourceToTasks[source.sourceId],
              source.videoTrack.isActive else { return }
        try await serialTasks.enqueue {
            Self.logger.debug("♼ Queue: Enabling track for source \(source.sourceId) on renderer \(ObjectIdentifier(renderer).debugDescription)")
            guard !Task.isCancelled, source.videoTrack.isActive else { return }
            if let layer {
                try await source.videoTrack.enable(renderer: renderer, layer: layer)
            } else {
                try await source.videoTrack.enable(renderer: renderer)
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
            Self.logger.debug("♼ Queue: Finished disabling track for source \(source.sourceId)")
        }
    }
}

// MARK: Helper functions

private extension VideoTracksManager {
    func addSimulcastLayers(_ layers: [MCRTSRemoteTrackLayer], for source: StreamSource) async {
        self.sourceToSimulcastLayersMapping[source.sourceId] = layers
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
            .compactMap { self.viewToRequestedVideoQualityMapping[$0] }
        let bestVideoQualityFromRequested = videoQualitiesRequestedForSource.bestVideoQualityFromTheRequestedList
        let layerToSelect = layers.matching(quality: bestVideoQualityFromRequested)

        let selectedVideoQuality: VideoQuality = layerToSelect == nil ? .auto : bestVideoQualityFromRequested
        let newVideoQualityAndLayerPair = VideoQualityAndLayerPair(videoQuality: selectedVideoQuality, layer: layerToSelect)

        let currentVideoQualityAndLayerPair = self.sourceToSelectedVideoQualityAndLayerMapping[source.sourceId]
        guard newVideoQualityAndLayerPair != currentVideoQualityAndLayerPair else {
            // Currently selected video quality matches the newly calculated one, no action needed
            Self.logger.debug("♼ Exiting - Currently selected videoquality \(selectedVideoQuality.displayText) for source \(sourceId) is already up to date")
            return
        }

        do {
            if let layerToSelect {
                Self.logger.debug("♼ Has simulcast layer - \(layerToSelect) for source \(sourceId)")
                Self.logger.debug("♼ Selecting videoquality \(selectedVideoQuality.displayText) for source \(sourceId) on view \(anyActiveView)")
                self.sourceToSelectedVideoQualityAndLayerMapping[sourceId] = newVideoQualityAndLayerPair

                let targetBitrateForLayer = self.getTargetBitrate(from: layerToSelect, sourceId: sourceId)
                self.sourcedTargetBitrates[sourceId] = targetBitrateForLayer

                try await self.queueEnableTrack(for: source, layer: MCRTSRemoteVideoTrackLayer(layer: layerToSelect))
            } else {
                Self.logger.debug("♼ No simulcast layer for source \(sourceId) matching \(bestVideoQualityFromRequested.displayText)")
                Self.logger.debug("♼ Selecting videoquality 'Auto' for source \(sourceId) on view \(anyActiveView)")
                self.sourceToSelectedVideoQualityAndLayerMapping[sourceId] = newVideoQualityAndLayerPair

                let targetBitrateForLayer = self.getTargetBitrate(from: newVideoQualityAndLayerPair.layer, sourceId: sourceId)
                self.sourcedTargetBitrates[sourceId] = targetBitrateForLayer

                try await self.queueEnableTrack(for: source)
            }
        } catch {
            Self.logger.debug("♼🛑 Enabling video track threw error \(error.localizedDescription)")
        }
    }

    func removeAllStoredData(for source: StreamSource) {
        let sourceId = source.sourceId
        let activeViews = self.sourceToActiveViewsMapping[sourceId]

        activeViews?.forEach { self.viewToRequestedVideoQualityMapping[$0] = nil }
        self.sourceToSimulcastLayersMapping[sourceId] = nil
        self.sourceToActiveViewsMapping[sourceId] = nil
    }

    func getTargetBitrate(from layer: MCRTSRemoteTrackLayer?, sourceId: SourceID) -> Int? {
        if let bitrate = layer?.targetBitrate {
            let targetBitrate = Int(truncating: bitrate)
            Self.logger.debug("♼ Updating target bitrate to \(targetBitrate) for source \(sourceId)")
            return targetBitrate
        }
        return nil
    }
}

// MARK: Helpers to manage `Event` Observations

private extension VideoTracksManager {
    func addLayerEventsObservationTask(_ task: Task<Void, Never>, for source: StreamSource) {
        self.layerEventsObservationDictionary[source.sourceId] = task
    }
}

private extension Array where Self.Element == VideoQuality {
    var bestVideoQualityFromTheRequestedList: VideoQuality {
        self.sorted(by: >).first ?? .auto
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

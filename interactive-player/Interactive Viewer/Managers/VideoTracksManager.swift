//
//  VideoTracksManager.swift
//

import Foundation
import Combine
import DolbyIORTSCore
import MillicastSDK
import os

final actor VideoTracksManager: Identifiable {

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

    // Stored tasks
    private var videoTrackStateObservationDictionary: [SourceID: Task<Void, Never>] = [:]
    private var layerEventsObservationDictionary: [SourceID: Task<Void, Never>] = [:]

    // View's rendering a source
    private var sourceToActiveViewsMapping: [SourceID: [ViewID]] = [:]

    // View's to requested video quality
    private var viewToRequestedVideoQualityMapping: [ViewID: VideoQuality] = [:]

    // Layer information
    private var sourceToSimulcastLayersMapping: [SourceID: [MCRTSRemoteTrackLayer]] = [:]
    private var sourceToSelectedVideoQualityAndLayerMapping: [SourceID: VideoQualityAndLayerPair] = [:] {
        didSet {
            let sourceToVideoQuality = sourceToSelectedVideoQualityAndLayerMapping
                .mapValues({
                    $0.videoQuality
                })
            videoQualitySubject.send(sourceToVideoQuality)
        }
    }

    private var sourceToTasks: [SourceID: SerialTasks<Void>] = [:]
    private var trackStateUpdateSubject: CurrentValueSubject<Void, Never>?
    private let videoQualitySubject: CurrentValueSubject<[SourceID: VideoQuality], Never> = CurrentValueSubject([:])

    let rendererRegistry: RendererRegistry
    lazy var selectedVideoQualityPublisher = videoQualitySubject.eraseToAnyPublisher()

    init(rendererRegistry: RendererRegistry = RendererRegistry()) {
        self.rendererRegistry = rendererRegistry
    }

    func setTrackStateUpdateSubject(_ subject: CurrentValueSubject<Void, Never>) {
        trackStateUpdateSubject = subject
    }

    func observeVideoTrackEvents(for source: StreamSource) {
        Task { [weak self] in
            guard let self else { return }

            Task {
                guard await self.videoTrackStateObservationDictionary[source.sourceId] == nil else {
                    return
                }

                let videoTrackStateObservation = Task {
                    for await activityEvent in source.videoTrack.activity() {
                        switch activityEvent {
                        case .active:
                            Self.logger.debug("♼ Video track for \(source.sourceId) is active")
                            await self.sendTrackUpdateEvent()

                        case .inactive:
                            Self.logger.debug("♼ Video track for \(source.sourceId) is inactive")
                            await self.removeAllStoredData(for: source)
                            await self.sendTrackUpdateEvent()
                        }
                    }
                }
                if await self.addVideoTrackObservationTask(videoTrackStateObservation, for: source) {
                    Self.logger.debug("♼ Registering for video track lifecycle events of \(source.sourceId)")
                    await videoTrackStateObservation.value
                }
            }

            Task {
                guard await self.layerEventsObservationDictionary[source.sourceId] == nil else {
                    return
                }
                let layerEventsObservationTask = Task {
                    for await layerEvent in source.videoTrack.layers() {
                        let simulcastLayers = layerEvent.layers()
                        await self.addSimulcastLayers(simulcastLayers, for: source)
                    }
                }

                if await self.addLayerEventsObservationTask(layerEventsObservationTask, for: source) {
                    Self.logger.debug("♼ Registering layers events of \(source.sourceId)")
                    await layerEventsObservationTask.value
                }
            }
        }
    }

    func reset() {
        videoTrackStateObservationDictionary.removeAll()
        layerEventsObservationDictionary.removeAll()
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
        Self.logger.debug("♼ Remove view \(view.description) for source \(sourceId)")
        // Remove view from the list of active views for that source
        if var activeViews = sourceToActiveViewsMapping[sourceId], activeViews.contains(where: { $0 == view }) {
            activeViews.removeAll(where: { $0 == view })
            sourceToActiveViewsMapping[source.sourceId] = !activeViews.isEmpty ? activeViews : nil
        }

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
        if sourceToTasks[source.sourceId] == nil {
            sourceToTasks[source.sourceId] = SerialTasks()
        }

        let renderer = rendererRegistry.sampleBufferRenderer(for: source).underlyingRenderer
        guard let serialTasks = sourceToTasks[source.sourceId] else { return }
        try await serialTasks.add {
            Self.logger.debug("♼ Queue: Enabling track for source \(source.sourceId) on renderer \(renderer.objectIdentifier.debugDescription)")
            if let layer {
                try await source.videoTrack.enable(renderer: renderer, layer: layer)
            } else {
                try await source.videoTrack.enable(renderer: renderer)
            }
            Self.logger.debug("♼ Queue: Finished enabling track for source \(source.sourceId) on renderer \(renderer.objectIdentifier.debugDescription)")
        }
    }

    func queueDisableTrack(for source: StreamSource) async throws {
        guard let serialTasks = sourceToTasks[source.sourceId] else { return }
        try await serialTasks.add {
            Self.logger.debug("♼ Queue: Disabling track for source \(source.sourceId)")
            try await source.videoTrack.disable()
            Self.logger.debug("♼ Queue: Finished disabling track for source \(source.sourceId)")
        }
    }
}

// MARK: Helper functions

private extension VideoTracksManager {

    func sendTrackUpdateEvent() {
        trackStateUpdateSubject?.send()
    }

    func addSimulcastLayers(_ layers: [MCRTSRemoteTrackLayer], for source: StreamSource) async {
        sourceToSimulcastLayersMapping[source.sourceId] = layers
        Self.logger.debug("♼ Add layers \(layers.count) for \(source.sourceId)")
        let sourceId = source.sourceId

        // Choose any active view to reenable the track
        guard let activeViews = sourceToActiveViewsMapping[sourceId], let anyActiveView = activeViews.first else {
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
    func addVideoTrackObservationTask(_ task: Task<Void, Never>, for source: StreamSource) -> Bool {
        if videoTrackStateObservationDictionary[source.sourceId] != nil {
            return false
        }
        videoTrackStateObservationDictionary[source.sourceId] = task
        return true
    }

    func addLayerEventsObservationTask(_ task: Task<Void, Never>, for source: StreamSource) -> Bool {
        if layerEventsObservationDictionary[source.sourceId] != nil {
            return false
        }
        layerEventsObservationDictionary[source.sourceId] = task
        return true
    }
}

extension MCVideoRenderer {
    var objectIdentifier: ObjectIdentifier {
        ObjectIdentifier(self)
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

actor SerialTasks<Success> {
    private var previousTask: Task<Success, Error>?

    func add(block: @Sendable @escaping () async throws -> Success) async throws -> Success {
        let task = Task { [previousTask] in
            _ = await previousTask?.result
            return try await block()
        }
        previousTask = task
        return try await task.value
    }
}

//
//  VideoTracksManager.swift
//

import Foundation
import Combine
import DolbyIORTSCore
import MillicastSDK
import os

final actor VideoTracksManager {
    private static let logger = Logger(
        subsystem: Bundle.module.bundleIdentifier!,
        category: String(describing: VideoTracksManager.self)
    )

    private struct VideoQualityAndLayerPair: Equatable {
        let videoQuality: VideoQuality
        let layer: MCRTSRemoteTrackLayer?

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.videoQuality == rhs.videoQuality && lhs.layer?.encodingId == rhs.layer?.encodingId
        }
    }

    private var videoTrackActivityObservationDictionary: [SourceID: Task<Void, Never>] = [:]
    private var layerEventsObservationDictionary: [SourceID: Task<Void, Never>] = [:]

    private var sourceToSimulcastLayersMapping: [SourceID: [MCRTSRemoteTrackLayer]] = [:]
    private var sourceToRenderersMapping: [SourceID: [MCVideoRenderer]] = [:]
    private var rendererToRequestedLayerMapping: [ObjectIdentifier: VideoQuality] = [:]
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
    lazy var videoQualityPublisher = videoQualitySubject.eraseToAnyPublisher()

    func setTrackStateUpdateSubject(_ subject: CurrentValueSubject<Void, Never>) {
        trackStateUpdateSubject = subject
    }

    func observeVideoTrackEvents(for source: StreamSource) {
        Task { [weak self] in
            guard let self else { return }

            Task {
                guard await self.videoTrackActivityObservationDictionary[source.sourceId] == nil else {
                    return
                }

                Self.logger.debug("♼ Registering for video track lifecycle events of \(source.sourceId)")
                let videoTrackActivityObservation = Task {
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
                await self.addVideoTrackObservationTask(videoTrackActivityObservation, for: source)
                await videoTrackActivityObservation.value
            }

            Task {
                guard await self.layerEventsObservationDictionary[source.sourceId] == nil else {
                    return
                }
                Self.logger.debug("♼ Registering layers events of \(source.sourceId)")
                let layerEventsObservationTask = Task {
                    for await layerEvent in source.videoTrack.layers() {
                        let simulcastLayers = layerEvent.layers()
                        await self.addSimulcastLayers(simulcastLayers, for: source)
                    }
                }

                await self.addLayerEventsObservationTask(layerEventsObservationTask, for: source)
                await layerEventsObservationTask.value
            }
        }
    }

    func reset() {
        videoTrackActivityObservationDictionary.removeAll()
        layerEventsObservationDictionary.removeAll()
    }

    func enableTrack(for source: StreamSource, renderer: MCVideoRenderer, preferredVideoQuality: VideoQuality) async {
        let rendererId = renderer.objectIdentifier
        let sourceId = source.sourceId
        Self.logger.debug("♼ Request to enable video track for source \(sourceId) with preferredVideoQuality \(preferredVideoQuality.displayText) from renderer \(rendererId.debugDescription)")

        // If the renderer has already requested the same video quality before? - exit
        guard rendererToRequestedLayerMapping[rendererId] != preferredVideoQuality else {
            Self.logger.debug("♼ Exiting - Renderer already present for source \(sourceId) with preferredVideoQuality \(preferredVideoQuality.displayText)")
            return
        }

        let renderersForSource = sourceToRenderersMapping[sourceId] ?? []
        // Calculate the video quality to project from the requested list
        // Note: Only one layer can be selected for a source at a given time
        var videoQualitiesRequestedForSource = renderersForSource
            .compactMap { rendererToRequestedLayerMapping[$0.objectIdentifier] }
        videoQualitiesRequestedForSource.append(preferredVideoQuality)
        let bestVideoQualityFromRequested = videoQualitiesRequestedForSource.bestVideoQualityFromTheRequestedList
        let simulcastLayers = sourceToSimulcastLayersMapping[sourceId]
        let layerToSelect = simulcastLayers.map { $0.matching(quality: bestVideoQualityFromRequested) } ?? nil
        Self.logger.debug("♼ Has \(simulcastLayers?.count ?? 0) simulcast layers for source \(sourceId)")

        let videoQualityToSelect: VideoQuality = layerToSelect == nil ? .auto : bestVideoQualityFromRequested
        let newVideoQualityAndLayerPair = VideoQualityAndLayerPair(videoQuality: videoQualityToSelect, layer: layerToSelect)

        Self.logger.debug("♼ Add renderer information for source \(sourceId) and renderer \(rendererId.debugDescription)")
        // Update renderer's requested video quality
        rendererToRequestedLayerMapping[rendererId] = preferredVideoQuality

        // Add new renderer to the list of renderers for that source
        if var renderers = sourceToRenderersMapping[sourceId] {
            renderers.append(renderer)
            sourceToRenderersMapping[source.sourceId] = renderers
        } else {
            sourceToRenderersMapping[source.sourceId] = [renderer]
        }

        do {
            if let layerToSelect {
                Self.logger.debug("♼ Simulcast layer - \(layerToSelect) for source \(sourceId)")
                Self.logger.debug("♼ Selecting videoquality \(videoQualityToSelect.displayText) for source \(sourceId) on renderer \(rendererId.debugDescription)")
                sourceToSelectedVideoQualityAndLayerMapping[sourceId] = newVideoQualityAndLayerPair

                try await queueEnableTrack(for: source, renderer: renderer, layer: MCRTSRemoteVideoTrackLayer(layer: layerToSelect))
            } else {
                Self.logger.debug("♼ No simulcast layer for source \(sourceId) matching \(bestVideoQualityFromRequested.displayText)")
                Self.logger.debug("♼ Selecting videoquality 'Auto' for source \(sourceId) on renderer \(rendererId.debugDescription)")
                sourceToSelectedVideoQualityAndLayerMapping[sourceId] = newVideoQualityAndLayerPair

                try await queueEnableTrack(for: source, renderer: renderer)
            }
        } catch {
            Self.logger.debug("♼🛑 Enabling video track threw error \(error.localizedDescription)")
        }
    }

    func disableTrack(for source: StreamSource, renderer: MCVideoRenderer) async {
        let rendererId = renderer.objectIdentifier
        let sourceId = source.sourceId
        Self.logger.debug("♼ Request to disable video track for source \(sourceId) from renderer \(rendererId.debugDescription)")

        Self.logger.debug("♼ Remove renderer information for source \(sourceId) and renderer \(rendererId.debugDescription)")
        // Remove renderer from the list of renderers for that source
        if var renderers = sourceToRenderersMapping[sourceId], renderers.contains(where: { $0.objectIdentifier == rendererId }) {
            renderers.removeAll(where: { $0.objectIdentifier == rendererId })
            sourceToRenderersMapping[source.sourceId] = !renderers.isEmpty ? renderers : nil
        }

        // Remove renderer from Renderer to requested video quality mapping
        rendererToRequestedLayerMapping[rendererId] = nil

        if let renderersForSource = sourceToRenderersMapping[sourceId], let activeRenderer = renderersForSource.first {
            // Calculate the video quality to project from the requested list
            // Note: Only one layer can be selected for a source at a given time
            let videoQualitiesRequestedForSource = renderersForSource.compactMap { rendererToRequestedLayerMapping[$0.objectIdentifier] }
            let bestVideoQualityFromRequested = videoQualitiesRequestedForSource.bestVideoQualityFromTheRequestedList
            let simulcastLayers = sourceToSimulcastLayersMapping[sourceId]
            let layerToSelect = simulcastLayers.map { $0.matching(quality: bestVideoQualityFromRequested) } ?? nil

            let selectedVideoQuality: VideoQuality = layerToSelect == nil ? .auto : bestVideoQualityFromRequested
            let newVideoQualityAndLayerPair = VideoQualityAndLayerPair(videoQuality: selectedVideoQuality, layer: layerToSelect)

            do {
                if let layerToSelect {
                    Self.logger.debug("♼ Has simulcast layer - \(layerToSelect) for source \(sourceId)")
                    Self.logger.debug("♼ Selecting videoquality \(selectedVideoQuality.displayText) for source \(sourceId) on renderer \(activeRenderer.objectIdentifier.debugDescription)")
                    sourceToSelectedVideoQualityAndLayerMapping[sourceId] = newVideoQualityAndLayerPair
                    try await queueEnableTrack(for: source, renderer: activeRenderer, layer: MCRTSRemoteVideoTrackLayer(layer: layerToSelect))
                } else {
                    Self.logger.debug("♼ No simulcast layer for source \(sourceId) matching \(bestVideoQualityFromRequested.displayText)")
                    Self.logger.debug("♼ Selecting videoquality 'Auto' for source \(sourceId) on renderer \(activeRenderer.objectIdentifier.debugDescription)")
                    sourceToSelectedVideoQualityAndLayerMapping[sourceId] = newVideoQualityAndLayerPair
                    try await queueEnableTrack(for: source, renderer: activeRenderer)
                }
            } catch {
                Self.logger.debug("♼🛑 Enabling video track threw error \(error.localizedDescription)")
            }
        } else {
            do {
                Self.logger.debug("♼ Disable video track for source \(sourceId) as there are no active renderers")

                // Remove selected Video quality for source
                sourceToSelectedVideoQualityAndLayerMapping[sourceId] = nil

                removeAllStoredData(for: source)

                try await queueDisableTrack(for: source)
            } catch {
                Self.logger.debug("♼🛑 Disabling video track threw error \(error.localizedDescription)")
            }
        }
    }

    func queueEnableTrack(for source: StreamSource, renderer: MCVideoRenderer, layer: MCRTSRemoteVideoTrackLayer? = nil) async throws {
        if sourceToTasks[source.sourceId] == nil {
            sourceToTasks[source.sourceId] = SerialTasks()
        }

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

        // Choose any active renderer to reenable the track
        guard let renderersForSource = sourceToRenderersMapping[sourceId], let activeRenderer = renderersForSource.first else {
            Self.logger.debug("♼ No active renderers for \(source.sourceId)")
            return
        }

        let rendererId = activeRenderer.objectIdentifier

        // Calculate the video quality to project from the requested list
        // Note: Only one layer can be selected for a source at a given time
        let videoQualitiesRequestedForSource = renderersForSource
            .compactMap { rendererToRequestedLayerMapping[$0.objectIdentifier] }
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
                Self.logger.debug("♼ Selecting videoquality \(selectedVideoQuality.displayText) for source \(sourceId) on renderer \(rendererId.debugDescription)")
                sourceToSelectedVideoQualityAndLayerMapping[sourceId] = newVideoQualityAndLayerPair
                try await queueEnableTrack(for: source, renderer: activeRenderer, layer: MCRTSRemoteVideoTrackLayer(layer: layerToSelect))
            } else {
                Self.logger.debug("♼ No simulcast layer for source \(sourceId) matching \(bestVideoQualityFromRequested.displayText)")
                Self.logger.debug("♼ Selecting videoquality 'Auto' for source \(sourceId) on renderer \(rendererId.debugDescription)")
                sourceToSelectedVideoQualityAndLayerMapping[sourceId] = newVideoQualityAndLayerPair
                try await queueEnableTrack(for: source, renderer: activeRenderer)
            }
        } catch {
            Self.logger.debug("♼🛑 Enabling video track threw error \(error.localizedDescription)")
        }
    }

    func removeAllStoredData(for source: StreamSource) {
        let sourceId = source.sourceId
        let renderers = sourceToRenderersMapping[sourceId]

        renderers?.forEach { rendererToRequestedLayerMapping[$0.objectIdentifier] = nil }
        sourceToSimulcastLayersMapping[sourceId] = nil
        sourceToRenderersMapping[sourceId] = nil
    }
}

// MARK: Helpers to manage `Event` Observations

private extension VideoTracksManager {
    func addVideoTrackObservationTask(_ task: Task<Void, Never>, for source: StreamSource) {
        if let existingTask = videoTrackActivityObservationDictionary[source.sourceId] {
            existingTask.cancel()
        }
        videoTrackActivityObservationDictionary[source.sourceId] = task
    }

    func addLayerEventsObservationTask(_ task: Task<Void, Never>, for source: StreamSource) {
        if let existingTask = layerEventsObservationDictionary[source.sourceId] {
            existingTask.cancel()
        }
        layerEventsObservationDictionary[source.sourceId] = task
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
            let _ = await previousTask?.result
            return try await block()
        }
        previousTask = task
        return try await task.value
    }
}

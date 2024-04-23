//
//  RendererRegistry.swift
//

import Foundation
import MillicastSDK
import os

protocol RendererRegistryProtocol: AnyObject {
    func registerRenderer(_ renderer: StreamSourceViewRenderer, with quality: VideoQuality)
    func deregisterRenderer(_ renderer: StreamSourceViewRenderer)

    func hasActiveRenderer(for track: MCVideoTrack) -> Bool
    func requestedVideoQuality(for track: MCVideoTrack) -> VideoQuality

    func reset()
}

final class RendererRegistry: RendererRegistryProtocol {
    private static let logger = Logger.make(category: String(describing: RendererRegistry.self))

    private typealias StreamRendererIdentifier = UUID
    private typealias TrackIdentifier = String
    private typealias ViewIdentifier = NSUUID

    private var rendererDictionary: [TrackIdentifier: NSHashTable<StreamSourceViewRenderer>] = [:]
    private var trackToVideoQualityDictionary: [TrackIdentifier: [StreamRendererIdentifier: VideoQuality]] = [:]

    func registerRenderer(_ renderer: StreamSourceViewRenderer, with quality: VideoQuality) {
        guard let trackID = renderer.videoTrack.getId() else {
            Self.logger.warning("📺 Register renderer \(renderer.id) called with an invalid VideoTrack")
            return
        }

        // Update the requested video quality for a specific renderer
        let rendererToQualityMapping: [StreamRendererIdentifier: VideoQuality]
        if var existingRendererToQualityMapping = trackToVideoQualityDictionary[trackID] {
            existingRendererToQualityMapping[renderer.id] = quality
            rendererToQualityMapping = existingRendererToQualityMapping
        } else {
            rendererToQualityMapping = [renderer.id: quality]
        }
        trackToVideoQualityDictionary[trackID] = rendererToQualityMapping

        Self.logger.debug("📺 Register renderer \(renderer.id)")
        if let renderers = rendererDictionary[trackID] {
            Self.logger.debug("📺 Renderer dictionary has an entry for trackID - \(trackID)")
            guard !renderers.contains(renderer) else {
                Self.logger.debug("📺 Renderer is already registered")
                return
            }
            renderers.add(renderer)
        } else {
            Self.logger.debug("📺 Create a new renderer list for trackID - \(trackID)")
            let renderers = NSHashTable<StreamSourceViewRenderer>(options: .weakMemory)
            renderers.add(renderer)
            rendererDictionary[trackID] = renderers
        }
    }

    func deregisterRenderer(_ renderer: StreamSourceViewRenderer) {
        guard let trackID = renderer.videoTrack.getId() else {
            Self.logger.warning("📺 Deregister renderer \(renderer.id) called with an invalid VideoTrack")
            return
        }

        Self.logger.debug("📺 Deregister renderer \(renderer.id)")
        if let renderers = rendererDictionary[trackID] {
            renderers.remove(renderer)
        }

        if var rendererToQualityMapping = trackToVideoQualityDictionary[trackID] {
            rendererToQualityMapping.removeValue(forKey: renderer.id)
            trackToVideoQualityDictionary[trackID] = rendererToQualityMapping
        }
    }

    func hasActiveRenderer(for track: MCVideoTrack) -> Bool {
        !activeRenderers(for: track).isEmpty
    }

    func requestedVideoQuality(for track: MCVideoTrack) -> VideoQuality {
        guard
            let trackID = track.getId(),
            let rendererToQualityMapping = trackToVideoQualityDictionary[trackID]
        else {
            return .auto
        }

        let sortedVideoQualityList = rendererToQualityMapping.values
            .sorted { $0.isGreaterThan(quality: $1) }
        return sortedVideoQualityList.first ?? .auto
    }

    private func activeRenderers(for track: MCVideoTrack) -> [StreamSourceViewRenderer] {
        guard
            let trackID = track.getId(),
            let renderers = rendererDictionary[trackID]
        else {
            return []
        }

        return renderers.allObjects
    }

    func reset() {
        Self.logger.debug("📺 Reset renderer registry")
        rendererDictionary.removeAll()
    }
}

fileprivate extension VideoQuality {
    func isGreaterThan(quality: VideoQuality?) -> Bool {
        switch (self, quality) {
        case (.auto, .high), (.auto, .medium), (.auto, .low), (.auto, nil),
            (.high, .medium), (.high, .low), (.high, nil),
            (.medium, .low), (.medium, nil),
            (.low, nil):
            return true
        default:
            return false
        }
    }
}

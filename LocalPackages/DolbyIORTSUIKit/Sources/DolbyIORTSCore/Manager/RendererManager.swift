//
//  RendererManager.swift
//

import Foundation
import MillicastSDK
import os

protocol RendererManagerProtocol: AnyObject {
    func addTrack(_ track: MCVideoTrack)
    func removeTrack(_ track: MCVideoTrack)

    func renderer(for track: MCVideoTrack, viewIdentifier: String) -> StreamSourceViewRenderer
    func removeRenderer(for track: MCVideoTrack, viewIdentifier: String)
    func numberOfRenderers(for track: MCVideoTrack) -> Int

    func reset()
}

final class RendererManager: RendererManagerProtocol {
    private var rendererDictionary: [String: [String: StreamSourceViewRenderer]] = [:]
    private var tracksDictionary: [String: MCVideoTrack] = [:]

    func addTrack(_ track: MCVideoTrack) {
        guard
            let trackID = track.getId(),
            rendererDictionary[trackID] == nil,
            tracksDictionary[trackID] == nil
        else {
            return
        }

        tracksDictionary[trackID] = track
        rendererDictionary[trackID] = [:]
    }

    func removeTrack(_ track: MCVideoTrack) {
        guard
            let trackID = track.getId(),
            rendererDictionary[trackID] != nil,
            tracksDictionary[trackID] != nil
        else {
            return
        }

        tracksDictionary.removeValue(forKey: trackID)
        rendererDictionary.removeValue(forKey: trackID)
    }

    func numberOfRenderers(for track: MCVideoTrack) -> Int {
        guard
            let trackID = track.getId(),
            let viewToRendererMapping = rendererDictionary[trackID]
        else {
            return 0
        }

        return viewToRendererMapping.values.count
    }

    func renderer(for track: MCVideoTrack, viewIdentifier: String) -> StreamSourceViewRenderer {
        guard
            let trackID = track.getId(),
            let track = tracksDictionary[trackID],
            var viewToRendererMapping = rendererDictionary[trackID]
        else {
            fatalError("Expect to have dictionary entry for the track before querying for renderer")
        }

        if let renderer = viewToRendererMapping[viewIdentifier] {
            return renderer
        } else {
            let renderer = MCIosVideoRenderer()
            Task {
                await MainActor.run {
                    track.add(renderer)
                }
            }

            let viewRenderer = StreamSourceViewRenderer(renderer: renderer)
            viewToRendererMapping[viewIdentifier] = viewRenderer
            rendererDictionary[trackID] = viewToRendererMapping

            return viewRenderer
        }
    }

    func removeRenderer(for track: MCVideoTrack, viewIdentifier: String) {
        guard
            let trackID = track.getId(),
            let track = tracksDictionary[trackID],
            var viewToRendererMapping = rendererDictionary[trackID],
            let viewRenderer = viewToRendererMapping[viewIdentifier]
        else {
            fatalError("Expect to have dictionary entry for the track before querying for renderer")
        }

        track.remove(viewRenderer.renderer)
        viewToRendererMapping.removeValue(forKey: viewIdentifier)

        rendererDictionary[trackID] = viewToRendererMapping
    }

    func reset() {
        rendererDictionary.removeAll()
        tracksDictionary.removeAll()
    }
}

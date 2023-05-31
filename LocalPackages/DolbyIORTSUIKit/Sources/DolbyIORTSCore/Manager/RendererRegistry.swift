//
//  RendererRegistry.swift
//

import Foundation
import MillicastSDK
import os

protocol RendererRegistryProtocol: AnyObject {
    func registerRenderer(_ renderer: StreamSourceViewRenderer, for track: MCVideoTrack)
    
    func hasActiveRenderer(for track: MCVideoTrack) -> Bool

    func reset()
}

final class RendererRegistry: RendererRegistryProtocol {
    private var rendererDictionary: [String: NSHashTable<StreamSourceViewRenderer>] = [:]

    func registerRenderer(_ renderer: StreamSourceViewRenderer, for track: MCVideoTrack) {
        guard let trackID = track.getId() else {
            fatalError("Expect to have dictionary entry for the track before querying for renderer")
        }

        if let renderers = rendererDictionary[trackID] {
            renderers.add(renderer)
        } else {
            let renderers = NSHashTable<StreamSourceViewRenderer>(options: .weakMemory)
            renderers.add(renderer)
        }
    }
    
    func hasActiveRenderer(for track: MCVideoTrack) -> Bool {
        guard
            let trackID = track.getId(),
            let renderers = rendererDictionary[trackID]
        else {
            return false
        }
        
        return renderers.count != 0
    }

    func reset() {
        rendererDictionary.removeAll()
    }
}

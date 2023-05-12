//
//  Renderer.swift
//

import Foundation
import MillicastSDK
import os

protocol RendererManagerProtocol: AnyObject {
    func addRenderer(sourceId: StreamSource.SourceId, track: MCVideoTrack) async
    func removeRenderer(sourceId: StreamSource.SourceId)
    func mainRenderer(for sourceId: StreamSource.SourceId) -> MCIosVideoRenderer?
    func subRenderer(for sourceId: StreamSource.SourceId) -> MCIosVideoRenderer?
    func reset()
}

final class RendererManager: RendererManagerProtocol {
    typealias MainAndSubRenderers = (main: MCIosVideoRenderer, sub: MCIosVideoRenderer)
    private(set) var rendererDictionary: [StreamSource.SourceId: MainAndSubRenderers] = [:]

    func addRenderer(sourceId: StreamSource.SourceId, track: MCVideoTrack) async {
        guard rendererDictionary[sourceId] == nil else {
            return
        }

        let renderers: MainAndSubRenderers = await MainActor.run {
            let mainRenderer = MCIosVideoRenderer()
            track.add(mainRenderer)

            let subRenderer = MCIosVideoRenderer()
            track.add(subRenderer)

            return (mainRenderer, subRenderer)
        }

        rendererDictionary[sourceId] = renderers
    }

    func removeRenderer(sourceId: StreamSource.SourceId) {
        rendererDictionary.removeValue(forKey: sourceId)
    }

    func mainRenderer(for sourceId: StreamSource.SourceId) -> MCIosVideoRenderer? {
        let renderers = rendererDictionary[sourceId]
        return renderers?.main
    }

    func subRenderer(for sourceId: StreamSource.SourceId) -> MCIosVideoRenderer? {
        let renderers = rendererDictionary[sourceId]
        return renderers?.sub
    }

    func reset() {
        rendererDictionary.removeAll()
    }
}

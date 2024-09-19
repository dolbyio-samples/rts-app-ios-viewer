//
//  RendererRegistry.swift
//

import Foundation
import MillicastSDK

public final class RendererRegistry {
    private var renderers: [SourceID: MCVideoSwiftUIView.Renderer] = [:]

    public init() {}

    public func sampleBufferRenderer(for source: StreamSource) -> MCVideoSwiftUIView.Renderer {
        if let renderer = renderers[source.sourceId] {
            return renderer
        } else {
            let renderer: MCVideoSwiftUIView.Renderer = .sampleBuffer(MCCMSampleBufferVideoRenderer())
            renderers[source.sourceId] = renderer
            return renderer
        }
    }
    
    public func acceleratedRenderer(for source: StreamSource) -> MCVideoSwiftUIView.Renderer {
        print("$$$ accelerated Renderer")
        if let renderer = renderers[source.sourceId] {
            return renderer
        } else {
            let renderer: MCVideoSwiftUIView.Renderer = .accelerated(MCAcceleratedVideoRenderer())
            renderers[source.sourceId] = renderer
            return renderer
        }
    }
}

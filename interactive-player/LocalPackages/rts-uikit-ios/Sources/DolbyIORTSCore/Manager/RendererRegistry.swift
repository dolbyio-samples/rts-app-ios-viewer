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

    public func accelaratedRenderer(for source: StreamSource) -> MCVideoSwiftUIView.Renderer {
        if let renderer = renderers[source.sourceId] {
            return renderer
        } else {
            let renderer: MCVideoSwiftUIView.Renderer = .accelerated(MCAcceleratedVideoRenderer())
            renderers[source.sourceId] = renderer
            return renderer
        }
    }
}

extension MCVideoSwiftUIView.Renderer {
    public var underlyingRenderer: MCVideoRenderer {
        switch self {
        case let .accelerated(renderer):
            return renderer
        case let .sampleBuffer(renderer):
            return renderer
        @unknown default:
            fatalError("Unknown renderer type")
        }
    }
}

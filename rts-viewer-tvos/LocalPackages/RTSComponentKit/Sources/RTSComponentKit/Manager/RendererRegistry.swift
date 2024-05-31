//
//  RendererRegistry.swift
//

import Foundation
import MillicastSDK

public final class RendererRegistry {
    private var renderers: [SourceID: MCVideoSwiftUIView.Renderer] = [:]

    public init() {}

    public func registerRenderer(renderer: MCVideoSwiftUIView.Renderer, for source: Source) {
        renderers[source.sourceId] = renderer
    }

    public func renderer(for source: Source) -> MCVideoSwiftUIView.Renderer {
        guard let renderer = renderers[source.sourceId] else {
            fatalError("Renderer requested for \(source.sourceId) before its registered")
        }

        return renderer
    }

    public func hasRenderer(for source: Source) -> Bool {
        renderers[source.sourceId] != nil
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

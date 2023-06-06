//
//  StreamSourceAndViewRenderers.swift
//

import DolbyIORTSCore
import Foundation

final class StreamSourceAndViewRenderers {
    private var primaryRendererDictionary: [UUID: StreamSourceViewRenderer] = [:]
    private var secondaryRendererDictionary: [UUID: StreamSourceViewRenderer] = [:]

    func primaryRenderer(for source: StreamSource) -> StreamSourceViewRenderer {
        if let renderer = primaryRendererDictionary[source.id] {
            return renderer
        } else {
            let renderer = StreamSourceViewRenderer(source)
            primaryRendererDictionary[source.id] = renderer
            return renderer
        }
    }

    func secondaryRenderer(for source: StreamSource) -> StreamSourceViewRenderer {
        if let renderer = secondaryRendererDictionary[source.id] {
            return renderer
        } else {
            let renderer = StreamSourceViewRenderer(source)
            secondaryRendererDictionary[source.id] = renderer
            return renderer
        }
    }
}

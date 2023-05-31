//
//  StreamSourceAndViewRenderers.swift
//

import DolbyIORTSCore
import Foundation

final class StreamSourceAndViewRenderers {
    private var rendererDictionary: [UUID: StreamSourceViewRenderer] = [:]

    func primaryRenderer(for source: StreamSource) -> StreamSourceViewRenderer {
        if let renderer = rendererDictionary[source.id] {
            return renderer
        } else {
            let renderer = StreamSourceViewRenderer(source)
            rendererDictionary[source.id] = renderer
            return renderer
        }
    }
}

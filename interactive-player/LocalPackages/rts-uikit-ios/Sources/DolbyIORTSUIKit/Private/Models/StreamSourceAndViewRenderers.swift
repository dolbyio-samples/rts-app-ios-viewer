//
//  StreamSourceAndViewRenderers.swift
//

import DolbyIORTSCore
import Foundation

final class ViewRendererProvider: ObservableObject {

    private var rendererDictionary: [String: StreamSourceViewRenderer] = [:]

    func renderer(for source: StreamSource, isPortait: Bool) -> StreamSourceViewRenderer {
        let orientationKey = isPortait ? "Portrait" : "Landscape"
        let storageKey = "\(source.id)_\(orientationKey)"
        if let renderer = rendererDictionary[storageKey] {
            return renderer
        } else {
            let renderer = StreamSourceViewRenderer(source)
            rendererDictionary[storageKey] = renderer
            return renderer
        }
    }
}

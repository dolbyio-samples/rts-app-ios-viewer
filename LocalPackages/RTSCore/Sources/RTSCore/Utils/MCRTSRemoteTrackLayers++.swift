//
//  MCRTSRemoteTrackLayers++.swift
//

import Foundation
import MillicastSDK

extension MCRTSRemoteTrackLayers {
    public func layers() -> [MCRTSRemoteTrackLayer] {
        var layersForSelection: [MCRTSRemoteTrackLayer] = []
        // Simulcast active layers
        let simulcastLayers = active.filter({ !$0.encodingId.isEmpty })
        if !simulcastLayers.isEmpty {
            // Select the max (best) temporal layer Id from a specific encodingId
            let dictionaryOfLayersMatchingEncodingId = Dictionary(grouping: simulcastLayers, by: { $0.encodingId })
            dictionaryOfLayersMatchingEncodingId.forEach { (_: String, layers: [MCRTSRemoteTrackLayer]) in
                // Picking the layer matching the max temporal layer id - represents the layer with the best FPS
                if let layerWithBestFrameRate = layers.first(where: { $0.temporalLayerId == $0.maxTemporalLayerId }) ?? layers.last {
                    layersForSelection.append(layerWithBestFrameRate)
                }
            }
        }

        layersForSelection = layersForSelection
            .sorted { lhs, rhs in
              if let rhsLayerResolution = rhs.resolution, let lhsLayerResolution = lhs.resolution {
                    return rhsLayerResolution.width < lhsLayerResolution.width || rhsLayerResolution.height < rhsLayerResolution.height
                } else {
                    return rhs.bitrate < lhs.bitrate
                }
            }

        return layersForSelection
    }
}

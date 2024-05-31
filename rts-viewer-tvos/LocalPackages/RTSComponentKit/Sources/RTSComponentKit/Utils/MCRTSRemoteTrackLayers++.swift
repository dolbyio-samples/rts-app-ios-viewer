//
//  MCRTSRemoteTrackLayers++.swift
//

import Foundation
import MillicastSDK

extension MCRTSRemoteTrackLayers {
    public func videoQualityList() -> [VideoQuality] {
        var layersForSelection: [MCRTSRemoteTrackLayer] = []
        // Simulcast active layers
        let simulcastLayers = self.active.filter({ !$0.encodingId.isEmpty })
        let svcLayers = self.active.filter({ $0.spatialLayerId != nil })
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
        // Using SVC layer selection logic
        else {
            let dictionaryOfLayersMatchingSpatialLayerId = Dictionary(grouping: svcLayers, by: { $0.spatialLayerId! })
            dictionaryOfLayersMatchingSpatialLayerId.forEach { (_: NSNumber, layers: [MCRTSRemoteTrackLayer]) in
                // Picking the layer matching the max temporal layer id - represents the layer with the best FPS
                if let layerWithBestFrameRate = layers.first(where: { $0.spatialLayerId == $0.maxSpatialLayerId }) ?? layers.last {
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
        let topSimulcastLayers = Array(layersForSelection.prefix(3))
        switch topSimulcastLayers.count {
        case 2:
            return [
                .auto,
                .high(topSimulcastLayers[0]),
                .low(topSimulcastLayers[1])
            ]
        case 3...Int.max:
            return [
                .auto,
                .high(topSimulcastLayers[0]),
                .medium(topSimulcastLayers[1]),
                .low(topSimulcastLayers[2])
            ]
        default:
            return [.auto]
        }

    }
}

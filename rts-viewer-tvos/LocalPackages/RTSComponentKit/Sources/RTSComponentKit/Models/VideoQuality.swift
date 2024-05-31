//
//  VideoQuality.swift
//

import Foundation
import MillicastSDK

public enum VideoQuality: Equatable, Hashable, Identifiable {

    case auto, high(MCRTSRemoteTrackLayer), medium(MCRTSRemoteTrackLayer), low(MCRTSRemoteTrackLayer)

    public var layer: MCRTSRemoteTrackLayer? {
        switch self {
        case .auto:
            return nil
        case let .high(layerData):
            return layerData
        case let .medium(layerData):
            return layerData
        case let .low(layerData):
            return layerData
        }
    }

    public var id: Self { return self }
}

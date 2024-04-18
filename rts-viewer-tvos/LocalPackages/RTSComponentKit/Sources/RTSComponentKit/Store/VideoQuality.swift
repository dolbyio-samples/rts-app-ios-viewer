//
//  VideoQuality.swift
//

import Foundation
import MillicastSDK

public enum VideoQuality: String, CaseIterable, Identifiable, Equatable {
    case auto, high, medium, low
    public var id: Self { self }
}

public enum DetailedVideoQuality: Equatable {
    case auto, high(MCLayerData), medium(MCLayerData), low(MCLayerData)

    var layer: MCLayerData? {
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

    var quality: VideoQuality {
        switch self {
        case .auto:
            return .auto
        case .high:
            return .high
        case .medium:
            return .medium
        case .low:
            return .low
        }
    }

    func matching(videoQuality: VideoQuality) -> DetailedVideoQuality? {
        switch (videoQuality, self) {
        case (.auto, .auto), (.low, .low), (.medium, .medium), (.high, .high):
            return self
        default:
            return nil
        }
    }
}

extension Array where Self.Element == DetailedVideoQuality {
    func matching(videoQuality: VideoQuality) -> DetailedVideoQuality? {
        first { $0.matching(videoQuality: videoQuality) != nil }
    }
}

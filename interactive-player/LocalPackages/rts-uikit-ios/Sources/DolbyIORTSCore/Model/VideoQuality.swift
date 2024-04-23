//
//  VideoQuality.swift
//

import Foundation

public enum VideoQuality: String, Equatable, CaseIterable, Identifiable {

    case auto
    case high
    case medium
    case low

    init(_ viewQualityInternal: StreamSource.LowLevelVideoQuality) {
        switch viewQualityInternal {
        case .auto:
            self = .auto
        case .high:
            self = .high
        case .medium:
            self = .medium
        case .low:
            self = .low
        }
    }

    public var description: String {
        switch self {
        case .auto:
            return "Auto"
        case .high:
            return "High"
        case .medium:
            return "Medium"
        case .low:
            return "Low"
        }
    }

    public var id: String {
        return rawValue
    }
}

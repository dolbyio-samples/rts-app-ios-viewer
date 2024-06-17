//
//  VideoQuality.swift
//

import Foundation

public enum VideoQuality: String, CaseIterable, RawRepresentable, Identifiable, Comparable {
    public var id: String { rawValue }

    case auto, high, medium, low

    public var displayText: String {
        rawValue.capitalized
    }

    public static func < (lhs: VideoQuality, rhs: VideoQuality) -> Bool {
        return switch (lhs, rhs) {
        case (.high, .medium),
            (.high, .low),
            (.high, .auto),
            (.medium, .low),
            (.medium, .auto),
            (.low, .auto):
            false
        default:
            true
        }
    }
}

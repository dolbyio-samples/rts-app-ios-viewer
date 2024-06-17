//
//  VideoQuality.swift
//

import Foundation

enum VideoQuality: String, CaseIterable, RawRepresentable, Identifiable, Comparable {
    var id: String { rawValue }

    case auto, high, medium, low

    var displayText: String {
        rawValue.capitalized
    }

    static func < (lhs: VideoQuality, rhs: VideoQuality) -> Bool {
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

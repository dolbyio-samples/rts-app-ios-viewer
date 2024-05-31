//
//  StatisticsViewModel.swift
//

import Combine
import Foundation
import OSLog
import RTSComponentKit
import UIKit

struct SimulcastViewModel {
    let source: Source
    let videoQualityList: [VideoQuality]
    let selectedVideoQuality: VideoQuality
}

extension VideoQuality {
    var displayText: String {
        switch self {
        case .auto:
            "Auto"
        case .high:
            "High"
        case .medium:
            "Medium"
        case .low:
            "Low"
        }
    }

    var encodingId: String {
        switch self {
        case .auto:
            "Auto"
        case let .high(layer):
            layer.encodingId
        case let .medium(layer):
            layer.encodingId
        case let .low(layer):
            layer.encodingId
        }
    }
}

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
  
    var targetInformation: String? {
      if let layer = layer {
        var target: [String] = []
        if let bitrate = layer.targetBitrate {
          target.append("bitrate: \(bitrate.intValue/1000) kbps")
        }
        if let resolution = layer.resolution {
          target.append("resolution: \(resolution.width)x\(resolution.height)")
        }
        if let fps = layer.targetFps {
          target.append("fps: \(fps)")
        }
        return "(\(target.joined(separator: ", ")))"
      }
      return nil
    }
}

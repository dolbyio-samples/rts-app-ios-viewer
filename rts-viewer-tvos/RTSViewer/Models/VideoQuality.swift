//
//  VideoQuality.swift
//

import Foundation
import MillicastSDK

enum VideoQuality: Identifiable, Equatable, Comparable {
    case auto
    case quality(MCRTSRemoteTrackLayer)

    init(layer: MCRTSRemoteTrackLayer) {
        self = .quality(layer)
    }
}

extension VideoQuality {
    static func < (lhs: VideoQuality, rhs: VideoQuality) -> Bool {
        return switch (lhs, rhs) {
        case(.quality, .auto):
            false
        case let (.quality(lhsQuality), .quality(rhsQuality)):
            lhsQuality == rhsQuality
        default:
            true
        }
    }

    var id: String {
        switch self {
        case .auto:
            "Auto"
        case let .quality(videoTrackLayer):
            videoTrackLayer.encodingId
        }
    }

    var displayText: String {
        switch self {
        case .auto:
            "Auto"
        case let .quality(layer):
            layer.resolution.map { "\($0.height)p" } ?? "Encoding id: \(layer.encodingId)"
        }
    }

    var encodingId: String {
        switch self {
        case .auto:
            "Auto"
        case let .quality(layer):
            layer.encodingId
        }
    }

    var layer: MCRTSRemoteTrackLayer? {
        switch self {
        case .auto:
            nil
        case let .quality(layer):
            layer
        }
    }

    var targetInformation: String? {
        guard let layer else {
            return nil
        }
        var target: [String] = []
        if let bitrate = layer.targetBitrate {
            target.append("Bitrate: \(bitrate.intValue / 1000) kbps")
        }
        if let resolution = layer.resolution {
            target.append("Resolution: \(resolution.width)x\(resolution.height)")
        }
        if let fps = layer.targetFps {
            target.append("FPS: \(fps)")
        }
        return "(\(target.joined(separator: ", ")))"
    }
}

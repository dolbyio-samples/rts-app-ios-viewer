//
//  Source.swift
//

import Foundation
import MillicastSDK

public enum SourceID: Equatable, Hashable, CustomStringConvertible {
    case main
    case other(sourceId: String)

    public init(sourceId: String?) {
        switch sourceId {
        case .none:
            self = .main
        case let .some(id) where id.isEmpty:
            self = .main
        case let .some(id):
            self = .other(sourceId: id)
        }
    }

    public var value: String? {
        return switch self {
        case .main:
            nil
        case let .other(sourceId: sourceId):
            sourceId
        }
    }

    public var description: String {
        return switch self {
        case .main:
            "main"
        case let .other(sourceId: sourceId):
            sourceId
        }
    }
}

public struct StreamSource: Identifiable {
    public let id = UUID()
    public let sourceId: SourceID
    public let videoTrack: MCRTSRemoteVideoTrack
    public private(set) var audioTrack: MCRTSRemoteAudioTrack?

    init(sourceId: SourceID, videoTrack: MCRTSRemoteVideoTrack, audioTrack: MCRTSRemoteAudioTrack? = nil) {
        self.sourceId = sourceId
        self.videoTrack = videoTrack
        self.audioTrack = audioTrack
    }

    mutating func addAudioTrack(_ track: MCRTSRemoteAudioTrack) {
        audioTrack = track
    }
}

extension StreamSource: Comparable {
    public static func < (lhs: StreamSource, rhs: StreamSource) -> Bool {
        switch (lhs.sourceId, rhs.sourceId) {
        case (.main, .main), (.other, .main):
            return false
        case (.main, .other):
            return true
        case let (.other(lhsSourceId), .other(rhsSourceId)):
            return lhsSourceId < rhsSourceId
        }
    }
}

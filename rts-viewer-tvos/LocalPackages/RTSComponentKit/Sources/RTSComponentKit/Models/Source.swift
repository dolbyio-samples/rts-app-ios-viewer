//
//  Source.swift
//

import Foundation
import MillicastSDK

public enum SourceID: Equatable, Hashable, CustomStringConvertible {
    public var description: String {
        return switch self {
        case .main:
            "main"
        case let .other(sourceId: sourceId):
            sourceId
        }
    }

    case main
    case other(sourceId: String)

    init(sourceId: String?) {
        switch sourceId {
        case let .some(id):
            self = .other(sourceId: id)
        case .none:
            self = .main
        }
    }
}

public class Source: Identifiable {
    public let id = UUID()
    public private(set) var sourceId: SourceID
    public internal(set) var videoTrack: MCRTSRemoteVideoTrack
    public internal(set) var audioTrack: MCRTSRemoteAudioTrack?

    public var isVideoTrackActive: Bool {
        videoTrack.isActive
    }

    public var isAudioTrackActive: Bool {
        audioTrack?.isActive ?? false
    }

    init(sourceId: SourceID, videoTrack: MCRTSRemoteVideoTrack, audioTrack: MCRTSRemoteAudioTrack? = nil) {
        self.sourceId = sourceId
        self.videoTrack = videoTrack
        self.audioTrack = audioTrack
    }
}

extension Source: Equatable, Hashable {
    public static func == (lhs: Source, rhs: Source) -> Bool {
        return lhs.id == rhs.id && lhs.audioTrack == rhs.videoTrack && lhs.videoTrack == rhs.videoTrack && lhs.sourceId == rhs.sourceId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

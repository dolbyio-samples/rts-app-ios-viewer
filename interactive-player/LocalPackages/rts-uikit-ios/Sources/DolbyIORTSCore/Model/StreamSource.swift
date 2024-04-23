//
//  StreamSource.swift
//

import Foundation
import MillicastSDK

public struct StreamSource: Equatable, Hashable, Identifiable {

    public enum SourceId: Equatable, Hashable, CustomStringConvertible {
        case main
        case other(sourceId: String)

        public init(id: String?) {
            switch id {
            case .none, .some(""):
                self = .main
            case let .some(id):
                self = .other(sourceId: id)
            }
        }

        public var value: String? {
            switch self {
            case .main:
                return nil
            case let .other(sourceId: id):
                return id
            }
        }

        public var description: String {
            "SourceId: \(String(describing: value))"
        }
    }

    enum MediaType: String, Equatable, CustomStringConvertible {
        case audio, video

        var description: String {
            "MediaType: \(rawValue)"
        }
    }

    struct TrackInfo: Equatable, Hashable, CustomStringConvertible {
        let mid: String
        let trackID: String
        let mediaType: MediaType

        var description: String {
            "TrackInfo: Mid - \(mid), trackID - \(trackID), media type - \(mediaType.rawValue)"
        }
    }

    struct AudioTrackInfo: Equatable, Hashable, CustomStringConvertible {
        public let trackInfo: TrackInfo
        public let track: MCAudioTrack
        public var trackId: String { track.getId() }

        init(mid: String, trackID: String, mediaType: MediaType, track: MCAudioTrack) {
            self.trackInfo = TrackInfo(mid: mid, trackID: trackID, mediaType: mediaType)
            self.track = track
        }

        public var description: String {
            "AudioTrackInfo: Remote Track Identifier - \(trackId), track info - \(trackInfo)"
        }
    }

    struct VideoTrackInfo: Equatable, Hashable, CustomStringConvertible {
        public let trackInfo: TrackInfo
        public let track: MCVideoTrack
        public var trackId: String { track.getId() }

        init(mid: String, trackID: String, mediaType: MediaType, track: MCVideoTrack) {
            self.trackInfo = TrackInfo(mid: mid, trackID: trackID, mediaType: mediaType)
            self.track = track
        }

        public var description: String {
            "VideoTrackInfo: Remote Track Identifier - \(trackId), track info - \(trackInfo)"
        }
    }

    enum LowLevelVideoQuality: Equatable, Hashable, CustomStringConvertible {
        case auto
        case high(layer: MCLayerData)
        case medium(layer: MCLayerData)
        case low(layer: MCLayerData)

        var layerData: MCLayerData? {
            switch self {
            case .auto:
                return nil
            case .high(layer: let layerData),
                    .medium(layer: let layerData),
                    .low(layer: let layerData):
                return layerData
            }
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.auto, .auto):
                return true
            case (.high(layer: let lhsLayerData), .high(layer: let rhsLayerData)),
                (.medium(layer: let lhsLayerData), .medium(layer: let rhsLayerData)),
                (.low(layer: let lhsLayerData), .low(layer: let rhsLayerData)):
                return lhsLayerData.spatialLayerId == rhsLayerData.spatialLayerId &&
                lhsLayerData.temporalLayerId == rhsLayerData.temporalLayerId &&
                lhsLayerData.encodingId == rhsLayerData.encodingId
            default:
                return false
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
    }

    public var audioTracksCount: Int { audioTracks.count }

    public let id: UUID
    public let streamId: String
    public let sourceId: SourceId
    let isPlayingAudio: Bool
    let isPlayingVideo: Bool
    let audioTracks: [AudioTrackInfo]
    let videoTrack: VideoTrackInfo
    let lowLevelVideoQualityList: [LowLevelVideoQuality]
    let selectedLowLevelVideoQuality: LowLevelVideoQuality
    public let streamingStatistics: StreamingStatistics?

    public var videoQualityList: [VideoQuality] {
        lowLevelVideoQualityList.map(VideoQuality.init)
    }

    public var selectedVideoQuality: VideoQuality {
        VideoQuality(selectedLowLevelVideoQuality)
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

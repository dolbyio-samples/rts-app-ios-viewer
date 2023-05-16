//
//  StreamSource.swift
//

import Foundation
import MillicastSDK

public struct StreamSource: Equatable, Hashable, Identifiable {

    public enum SourceId: Equatable, Hashable {
        case main
        case other(sourceId: String)

        init(id: String?) {
            switch id {
            case .none:
                self = .main
            case let .some(id):
                self = .other(sourceId: id)
            }
        }

        var value: String? {
            switch self {
            case .main:
                return nil
            case let .other(sourceId: id):
                return id
            }
        }
    }

    public enum TrackType: String, Equatable {
        case audio, video
    }

    public enum MediaType: String, Equatable {
        case audio, video
    }

    public struct AudioTrackInfo: Equatable, Hashable {
        public let mid: String
        public let trackType: TrackType
        public let mediaType: MediaType
        public let track: MCAudioTrack

        public var trackId: String { track.getId() }
    }

    public struct VideoTrackInfo: Equatable, Hashable {
        public let mid: String
        public let trackType: TrackType
        public let mediaType: MediaType
        public let track: MCVideoTrack

        public var trackId: String { track.getId() }
    }

    public enum VideoQuality: Equatable, Hashable {
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
    }

    public let id: UUID
    public let streamId: String
    public let sourceId: SourceId
    public let audioTracks: [AudioTrackInfo]
    public let videoTrack: VideoTrackInfo?
    public let availableVideoQualityList: [VideoQuality]
    public let preferredVideoQuality: VideoQuality
    public let isPlayingAudio: Bool
    public let isPlayingVideo: Bool
}

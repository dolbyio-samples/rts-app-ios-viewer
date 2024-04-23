//
//  StreamSourceBuilder.swift
//

import Foundation
import MillicastSDK
import os

final class StreamSourceBuilder {
    private static let logger = Logger.make(category: String(describing: StreamSourceBuilder.self))

    enum BuildError: Error {
        case missingVideoTrack
        case missingAudioTrack
    }

    struct TrackItem {
        let trackID: String
        let mediaType: StreamSource.MediaType

        init?(track: String) {
            guard let mediaType = StreamSource.MediaType(rawValue: track) else {
                return nil
            }
            self.mediaType = mediaType
            self.trackID = track
        }
    }

    let identifier: UUID
    private(set) var streamId: String
    private(set) var sourceId: StreamSource.SourceId
    private(set) var supportedTrackItems: [TrackItem]
    private(set) var videoTrack: StreamSource.VideoTrackInfo?
    private(set) var audioTracks: [StreamSource.AudioTrackInfo] = []
    private(set) var availableVideoQualityList: [StreamSource.LowLevelVideoQuality] = [.auto]
    private(set) var isPlayingAudio = false
    private(set) var isPlayingVideo = false
    private(set) var streamingStatistics: StreamingStatistics?
    private(set) var selectedVideoQuality: StreamSource.LowLevelVideoQuality = .auto

    init(streamId: String, sourceId: String?, tracks: [String]) {
        identifier = UUID()
        self.streamId = streamId
        self.sourceId = StreamSource.SourceId(id: sourceId)

        supportedTrackItems = tracks
            .compactMap { TrackItem(track: $0) }
        Self.logger.debug("🧱 Supported track items \(self.supportedTrackItems) for \(self.sourceId)")
    }

    func addAudioTrack(_ track: MCAudioTrack, mid: String) {
        let trackItems = supportedTrackItems.filter({ $0.mediaType == .audio })
        guard
            !trackItems.isEmpty,
            audioTracks.count < trackItems.count
        else {
            return
        }
        let trackItem = trackItems[0]
        let audioTrack = StreamSource.AudioTrackInfo(
            mid: mid,
            trackID: trackItem.trackID,
            mediaType: trackItem.mediaType,
            track: track
        )
        audioTracks.append(audioTrack)
        Self.logger.debug("🧱 Add audio track for \(audioTrack) for \(self.sourceId)")
    }

    func addVideoTrack(_ track: MCVideoTrack, mid: String) {
        guard let trackItem = supportedTrackItems.first(where: { $0.mediaType == .video }) else {
            return
        }

        let videoTrack = StreamSource.VideoTrackInfo(
            mid: mid,
            trackID: trackItem.trackID,
            mediaType: trackItem.mediaType,
            track: track
        )
        self.videoTrack = videoTrack
        Self.logger.debug("🧱 Add video track for \(videoTrack) for \(self.sourceId)")
    }

    func setAvailableVideoQualityList(_ list: [StreamSource.LowLevelVideoQuality]) {
        availableVideoQualityList = list
        Self.logger.debug("🧱 Set available video quality list \(list) for \(self.sourceId)")
        if let newVideoQuality = availableVideoQualityList.matching(videoQuality: VideoQuality(selectedVideoQuality)) {
            selectedVideoQuality = newVideoQuality
        } else {
            selectedVideoQuality = .auto
        }
    }

    func setSelectedVideoQuality(_ videoQuality: VideoQuality) {
        guard let videoQualityToSelect = availableVideoQualityList.matching(videoQuality: videoQuality) else {
            selectedVideoQuality = .auto
            return
        }

        selectedVideoQuality = videoQualityToSelect
        Self.logger.debug("🧱 Set selected video quality \(videoQualityToSelect) for \(self.sourceId)")
    }

    func setPlayingAudio(_ enable: Bool) {
        isPlayingAudio = enable
        Self.logger.debug("🧱 Set audio playing state to \(enable) for \(self.sourceId)")
    }

    func setPlayingVideo(_ enable: Bool) {
        isPlayingVideo = enable
        Self.logger.debug("🧱 Set video playing state to \(enable) for \(self.sourceId)")
    }

    func setStatistics(_ statistics: StreamingStatistics) {
        streamingStatistics = statistics
    }

    func build(isAudioEnabled: Bool) throws -> StreamSource {
        if isAudioEnabled, hasMissingAudioTrack {
            throw BuildError.missingAudioTrack
        }

        guard !hasMissingVideoTrack, let videoTrack = videoTrack else {
            throw BuildError.missingVideoTrack
        }

        return StreamSource(
            id: identifier,
            streamId: streamId,
            sourceId: sourceId,
            isPlayingAudio: isPlayingAudio,
            isPlayingVideo: isPlayingVideo,
            audioTracks: audioTracks,
            videoTrack: videoTrack,
            lowLevelVideoQualityList: availableVideoQualityList,
            selectedLowLevelVideoQuality: selectedVideoQuality,
            streamingStatistics: streamingStatistics
        )
    }
}

// MARK: Helper functions

// Note: Currently the Millicast SDK callbacks do not give us a way to associate the track we receive in onAudioTrack(..) and onVideoTrack(..) callbacks to a particular SourceId
// The current implementation worked around it be checking for the missing `audio or video tracks` by comparing it with the `supportedTrackItems` - this SDK limitation leads
// us in making assumptions that the mediaType will either be "audio" or "video".
// TODO: Refactor this implementation when the SDK Callback API's are refined.
extension StreamSourceBuilder {
    var hasMissingAudioTrack: Bool {
        let audioTrackItems = supportedTrackItems.filter { $0.mediaType == .audio }
        return audioTracks.count < audioTrackItems.count
    }

    var hasMissingVideoTrack: Bool {
        let hasVideoTrack = supportedTrackItems.contains { $0.mediaType == .video }
        return hasVideoTrack && videoTrack == nil
    }
}

extension Array where Self.Element == StreamSource.LowLevelVideoQuality {
    func matching(videoQuality: VideoQuality) -> Self.Element? {
        return self.first { internalVideoQuality in
            switch (internalVideoQuality, videoQuality) {
            case (.auto, .auto), (.high, .high), (.medium, .medium), (.low, .low):
                return true
            default:
                return false
            }
        }
    }
}

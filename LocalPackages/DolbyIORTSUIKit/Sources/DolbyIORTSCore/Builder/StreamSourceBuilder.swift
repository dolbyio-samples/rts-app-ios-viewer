//
//  StreamSourceBuilder.swift
//

import Foundation
import MillicastSDK

final class StreamSourceBuilder {

    enum BuildError: Error {
        case missingVideoTrack
        case missingAudioTrack
    }

    struct TrackItem {
        let trackType: StreamSource.TrackType
        let mediaType: StreamSource.MediaType

        /// Initialises the Track Item, if possible from the passed-in String
        /// - Parameter track: A string value passed in by the SDK and is expected to be of format `{mediaType}/{trackType}`
        init?(track: String) {
            let trackInfoList = track.split(separator: "/")

            guard
                trackInfoList.count == 2,
                let mediaType = StreamSource.MediaType(rawValue: String(trackInfoList[0])),
                let trackType = StreamSource.TrackType(rawValue: String(trackInfoList[1]))
            else {
                return nil
            }
            self.mediaType = mediaType
            self.trackType = trackType
        }
    }

    let identifier: UUID
    private(set) var streamId: String
    private(set) var sourceId: StreamSource.SourceId
    private(set) var supportedTrackItems: [TrackItem]
    private(set) var videoTrack: StreamSource.VideoTrackInfo?
    private(set) var audioTracks: [StreamSource.AudioTrackInfo] = []
    private(set) var availableVideoQualityList: [StreamSource.VideoQuality] = [.auto]
    private(set) var preferredVideoQuality: StreamSource.VideoQuality = .auto
    private(set) var isPlayingAudio = false
    private(set) var isPlayingVideo = false

    init(streamId: String, sourceId: String?, tracks: [String]) {
        identifier = UUID()
        self.streamId = streamId
        self.sourceId = StreamSource.SourceId(id: sourceId)

        supportedTrackItems = tracks
            .compactMap { TrackItem(track: $0) }
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
        audioTracks.append(
            StreamSource.AudioTrackInfo(
                mid: mid,
                trackType: trackItem.trackType,
                mediaType: trackItem.mediaType,
                track: track)
        )
    }

    func addVideoTrack(_ track: MCVideoTrack, mid: String) {
        guard let trackItem = supportedTrackItems.first(where: { $0.mediaType == .video }) else {
            return
        }

        videoTrack = StreamSource.VideoTrackInfo(
            mid: mid,
            trackType: trackItem.trackType,
            mediaType: trackItem.mediaType,
            track: track
        )
    }

    func updatePreferredVideoQuality(_ videoQuality: StreamSource.VideoQuality) {
        guard availableVideoQualityList.contains(where: { $0 == videoQuality }) else {
            preferredVideoQuality = .auto
            return
        }

        preferredVideoQuality = videoQuality
    }

    func setAvailableVideoQualityList(_ list: [StreamSource.VideoQuality]) {
        availableVideoQualityList = list
    }

    func setPlayingAudio(_ enable: Bool) {
        isPlayingAudio = enable
    }

    func setPlayingVideo(_ enable: Bool) {
        isPlayingVideo = enable
    }

    func build() throws -> StreamSource {
        guard !hasMissingAudioTrack else {
            throw BuildError.missingAudioTrack
        }

        guard !hasMissingVideoTrack else {
            throw BuildError.missingVideoTrack
        }

        return StreamSource(
            id: identifier,
            streamId: streamId,
            sourceId: sourceId,
            availableVideoQualityList: availableVideoQualityList,
            preferredVideoQuality: preferredVideoQuality,
            isPlayingAudio: isPlayingAudio,
            isPlayingVideo: isPlayingVideo,
            audioTracks: audioTracks,
            videoTrack: videoTrack
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

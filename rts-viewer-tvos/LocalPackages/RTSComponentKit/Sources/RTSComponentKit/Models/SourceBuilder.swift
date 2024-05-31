//
//  SourceBuilder.swift
//

import Combine
import Foundation
import MillicastSDK

class SourceBuilder {

    // MARK: Private properties

    private class PartialSource {
        var sourceId: SourceID
        var videoTrack: MCRTSRemoteVideoTrack? {
            didSet {
                if let videoTrack {
                    source = Source(sourceId: sourceId, videoTrack: videoTrack)
                }
            }
        }
        var audioTrack: MCRTSRemoteAudioTrack? {
            didSet {
                if let source, let audioTrack {
                    source.audioTrack = audioTrack
                }
            }
        }

        private(set) var source: Source?

        init(sourceId: SourceID, videoTrack: MCRTSRemoteVideoTrack? = nil, audioTrack: MCRTSRemoteAudioTrack? = nil) {
            self.sourceId = sourceId
            self.videoTrack = videoTrack
            self.audioTrack = audioTrack
        }
    }

    private let sourceSubject: PassthroughSubject<[Source], Never> = .init()
    private var sources: [Source] = [] {
        didSet {
            sourceSubject.send(sources)
        }
    }
    private var partialSources: [PartialSource] = [] {
        didSet {
            sources = partialSources
                .compactMap { $0.source }
        }
    }

    // MARK: Internal properties

    lazy var sourcePublisher: AnyPublisher<[Source], Never> = sourceSubject.eraseToAnyPublisher()

    func addTrack(_ track: MCRTSRemoteTrack) {
        let sourceID = SourceID(sourceId: track.sourceID)

        let partialSource = partialSources.first(where: { $0.sourceId == sourceID }) ?? PartialSource(sourceId: sourceID)
        if let audioTrack = track.asAudio() {
            partialSource.audioTrack = audioTrack
        } else if let videoTrack = track.asVideo() {
            partialSource.videoTrack = videoTrack
        }

        if partialSources.firstIndex(where: { $0.sourceId == sourceID }) == nil {
            partialSources.append(partialSource)
        }
    }

    func reset() {
        partialSources.removeAll()
    }
}

//
//  SourceBuilder.swift
//

import Combine
import Foundation
import MillicastSDK
import os

private class PartialSource {
    var sourceId: SourceID
    
    var videoTrack: MCRTSRemoteVideoTrack? {
        didSet {
            if let videoTrack {
                source = StreamSource(sourceId: sourceId, videoTrack: videoTrack, audioTrack: audioTrack)
            }
        }
    }
    var audioTrack: MCRTSRemoteAudioTrack? {
        didSet {
            if let audioTrack {
                source?.addAudioTrack(audioTrack)
            }
        }
    }
    private(set) var source: StreamSource?

    init(sourceId: SourceID) {
        self.sourceId = sourceId
    }
}

final class SourceBuilder {
    static let logger = Logger(
        subsystem: Bundle.module.bundleIdentifier!,
        category: String(describing: SourceBuilder.self)
    )

    // MARK: Private properties
    private var audioTrackActivityObservationDictionary: [SourceID: Task<Void, Never>] = [:]
    private var videoTrackActivityObservationDictionary: [SourceID: Task<Void, Never>] = [:]

    private let audioTrackStateUpdateSubject: PassthroughSubject<SourceID, Never> = PassthroughSubject()
    private let videoTrackStateUpdateSubject: PassthroughSubject<SourceID, Never> = PassthroughSubject()

    private(set) var sources: [StreamSource] = [] {
        didSet {
            Self.logger.debug("👨‍🔧 Sources updated, \(self.sources)")
            sourceStreamContinuation.yield(sources)
        }
    }

    private var partialSources: [PartialSource] = []

    // MARK: Internal properties

    private(set) var sourceStream: AsyncStream<[StreamSource]>!
    private var sourceStreamContinuation: AsyncStream<[StreamSource]>.Continuation!
    private var subscriptions: Set<AnyCancellable> = []

    init() {
        let stream = AsyncStream { continuation in
            self.sourceStreamContinuation = continuation
        }
        self.sourceStream = stream
        
        audioTrackStateUpdateSubject
            .sink { [weak self] sourceId in
                guard let self, let source = self.partialSources.first(where: { $0.sourceId == sourceId }) else {
                    return
                }
                Self.logger.debug("👨‍🔧 Handle audio track active state change \(sourceId); isActive \(source.audioTrack?.isActive == true)")
                self.sourceStreamContinuation.yield(self.sources)
            }
            .store(in: &subscriptions)

        videoTrackStateUpdateSubject
            .sink { [weak self] sourceId in
                guard let self, let source = self.partialSources.first(where: { $0.sourceId == sourceId }) else {
                    return
                }
                Self.logger.debug("👨‍🔧 Handle video track active state change \(sourceId); isActive \(source.videoTrack?.isActive == true)")
                self.sourceStreamContinuation.yield(self.sources)
            }
            .store(in: &subscriptions)
    }

    func addTrack(_ track: MCRTSRemoteTrack) {
        let sourceID = SourceID(sourceId: track.sourceID)

        let partialSource = partialSources.first(where: { $0.sourceId == sourceID }) ?? PartialSource(sourceId: sourceID)
        if let audioTrack = track.asAudio() {
            partialSource.audioTrack = audioTrack
            observeAudioTrackEvents(for: audioTrack, sourceId: sourceID)
        } else if let videoTrack = track.asVideo() {
            partialSource.videoTrack = videoTrack
            observeVideoTrackEvents(for: videoTrack, sourceId: sourceID)
        }

        if partialSources.firstIndex(where: { $0.sourceId == sourceID }) == nil {
            partialSources.append(partialSource)
        }
        guard let newSource = partialSource.source else {
            return
        }

        if !sources.contains(where: { $0.sourceId == newSource.sourceId }) {
            sources.append(newSource)
        } else if let index = sources.firstIndex(where: { $0.sourceId == newSource.sourceId }) {
            var updatesSources = sources
            updatesSources.remove(at: index)
            updatesSources.insert(newSource, at: index)
            sources = updatesSources
        }
    }

    func reset() {
        Self.logger.debug("👨‍🔧 Reset source builder")

        partialSources.removeAll()
        subscriptions.removeAll()

        audioTrackActivityObservationDictionary.forEach { (sourceId, _) in
            audioTrackActivityObservationDictionary[sourceId]?.cancel()
            audioTrackActivityObservationDictionary[sourceId] = nil
        }

        videoTrackActivityObservationDictionary.forEach { (sourceId, _) in
            videoTrackActivityObservationDictionary[sourceId]?.cancel()
            videoTrackActivityObservationDictionary[sourceId] = nil
        }
    }
}

private extension SourceBuilder {

    func observeAudioTrackEvents(for track: MCRTSRemoteAudioTrack, sourceId: SourceID) {
        Task { [weak self] in
            guard let self, self.audioTrackActivityObservationDictionary[sourceId] == nil else {
                return
            }
            Self.logger.debug("👨‍🔧 Registering for audio track lifecycle events of \(sourceId)")
            let audioTrackActivityObservation = Task {
                for await activityEvent in track.activity() {
                    guard !Task.isCancelled else { return }
                    switch activityEvent {
                    case .active:
                        Self.logger.debug("👨‍🔧 Audio track for \(sourceId) is active, \(track.isActive)")
                        self.audioTrackStateUpdateSubject.send(sourceId)
                        
                    case .inactive:
                        Self.logger.debug("👨‍🔧 Audio track for \(sourceId) is inactive, \(track.isActive)")
                        self.audioTrackStateUpdateSubject.send(sourceId)
                    }
                }
            }
            self.audioTrackActivityObservationDictionary[sourceId] = audioTrackActivityObservation
            await audioTrackActivityObservation.value
        }
    }

    func observeVideoTrackEvents(for track: MCRTSRemoteVideoTrack, sourceId: SourceID) {
        Task { [weak self] in
            guard let self, self.videoTrackActivityObservationDictionary[sourceId] == nil else { return }

            Self.logger.debug("👨‍🔧 Registering for video track lifecycle events of \(sourceId)")
            let videoTrackActivityObservation = Task {
                for await activityEvent in track.activity() {
                    guard !Task.isCancelled else { return }
                    switch activityEvent {
                    case .active:
                        Self.logger.debug("👨‍🔧 Video track for \(sourceId) is active, \(track.isActive)")
                        self.videoTrackStateUpdateSubject.send(sourceId)
                        
                    case .inactive:
                        Self.logger.debug("👨‍🔧 Video track for \(sourceId) is inactive, \(track.isActive)")
                        self.videoTrackStateUpdateSubject.send(sourceId)
                    }
                }
            }
            self.videoTrackActivityObservationDictionary[sourceId] = videoTrackActivityObservation
            await videoTrackActivityObservation.value
        }
    }
}

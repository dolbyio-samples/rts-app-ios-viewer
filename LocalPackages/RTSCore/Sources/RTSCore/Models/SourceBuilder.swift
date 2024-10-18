//
//  SourceBuilder.swift
//

import Combine
import Foundation
import MillicastSDK
import os

private class PartialSource {
    var videoTrack: MCRTSRemoteVideoTrack? {
        didSet {
            if let videoTrack {
                source?.addVideoTrack(videoTrack)
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
    let sourceId: SourceID

    init(sourceId: SourceID) {
        self.sourceId = sourceId
        self.source = StreamSource(sourceId: sourceId)
    }
}

final actor SourceBuilder {
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
                guard let self else { return }
                Task {
                    guard let source = await self.partialSources.first(where: { $0.sourceId == sourceId }) else {
                        return
                    }
                    Self.logger.debug("👨‍🔧 Handle audio track active state change \(sourceId); isActive \(source.audioTrack?.isActive == true)")
                    await self.sourceStreamContinuation.yield(self.sources)
                }
            }
            .store(in: &subscriptions)

        videoTrackStateUpdateSubject
            .sink { [weak self] sourceId in
                guard let self else { return }
                Task {
                    guard let source = await self.partialSources.first(where: { $0.sourceId == sourceId }) else {
                        return
                    }
                    Self.logger.debug("👨‍🔧 Handle video track active state change \(sourceId); isActive \(source.videoTrack?.isActive == true)")
                    await self.sourceStreamContinuation.yield(self.sources)
                }
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

    func setAudioTrackObservation(task: Task<Void, Never>, for sourceId: SourceID) {
        audioTrackActivityObservationDictionary[sourceId] = task
    }
    
    func setVideoTrackObservation(task: Task<Void, Never>, for sourceId: SourceID) {
        videoTrackActivityObservationDictionary[sourceId] = task
    }

    func observeAudioTrackEvents(for track: MCRTSRemoteAudioTrack, sourceId: SourceID) {
        Task { [weak self] in
            guard let self, await self.audioTrackActivityObservationDictionary[sourceId] == nil else {
                return
            }
            Self.logger.debug("👨‍🔧 Registering for audio track lifecycle events of \(sourceId)")
            let audioTrackActivityObservation = Task {
                for await activityEvent in track.activity() {
                    guard !Task.isCancelled else { return }
                    switch activityEvent {
                    case .active:
                        Self.logger.debug("👨‍🔧 Audio track for \(sourceId) is active")
                        self.audioTrackStateUpdateSubject.send(sourceId)
                        
                    case .inactive:
                        Self.logger.debug("👨‍🔧 Audio track for \(sourceId) is inactive")
                        do {
                            try await track.disable()
                        } catch {
                            Self.logger.debug("👨‍🔧 Error disabling audio track for \(sourceId), \(error.localizedDescription)")
                        }
                        self.audioTrackStateUpdateSubject.send(sourceId)
                    }
                }
            }
            await self.setAudioTrackObservation(task: audioTrackActivityObservation, for: sourceId)
            await audioTrackActivityObservation.value
        }
    }

    func observeVideoTrackEvents(for track: MCRTSRemoteVideoTrack, sourceId: SourceID) {
        Task { [weak self] in
            guard let self, await self.videoTrackActivityObservationDictionary[sourceId] == nil else { return }

            Self.logger.debug("👨‍🔧 Registering for video track lifecycle events of \(sourceId)")
            let videoTrackActivityObservation = Task {
                for await activityEvent in track.activity() {
                    guard !Task.isCancelled else { return }
                    switch activityEvent {
                    case .active:
                        Self.logger.debug("👨‍🔧 Video track for \(sourceId) is active")
                        self.videoTrackStateUpdateSubject.send(sourceId)
                        
                    case .inactive:
                        Self.logger.debug("👨‍🔧 Video track for \(sourceId) is inactive")
                        do {
                            try await track.disable()
                        } catch {
                            Self.logger.debug("👨‍🔧 Error disabling video track for \(sourceId), \(error.localizedDescription)")
                        }
                        self.videoTrackStateUpdateSubject.send(sourceId)
                    }
                }
            }

            await self.setVideoTrackObservation(task: videoTrackActivityObservation, for: sourceId)
            await videoTrackActivityObservation.value
        }
    }
}

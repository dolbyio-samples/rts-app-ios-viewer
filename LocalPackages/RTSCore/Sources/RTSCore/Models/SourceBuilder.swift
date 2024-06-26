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
                // Track is active when its first received
                isVideoActive = true
                source?.setAudioActive(isAudioActive)
            }
        }
    }
    var audioTrack: MCRTSRemoteAudioTrack? {
        didSet {
            if let audioTrack {
                source?.addAudioTrack(audioTrack)
                // Track is active when its first received
                isAudioActive = true
            }
        }
    }

    var isVideoActive: Bool = false {
        didSet {
            source?.setVideoActive(isVideoActive)
        }
    }

    var isAudioActive: Bool = false {
        didSet {
            source?.setAudioActive(isAudioActive)
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

    // FIXME: `MCRTSRemoteTrack.isActive` returns true even after receiving an inactive event.
    // This prevents the application from filtering a list of active sources(video tracks) from the sources(video tracks) list
    // The workaround is to maintain the list locally
    private var inactiveVideoSources: Set<SourceID> = []
    private var inactiveAudioSources: Set<SourceID> = []
    private let audioTrackStateUpdateSubject: PassthroughSubject<(SourceID, Bool), Never> = PassthroughSubject()
    private let videoTrackStateUpdateSubject: PassthroughSubject<(SourceID, Bool), Never> = PassthroughSubject()

    private var sources: [StreamSource] = [] {
        didSet {
            sources.forEach { observeTrackEvents(for: $0) }
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
            .sink { [weak self] sourceId, active in
                guard let self, let source = self.partialSources.first(where: { $0.sourceId == sourceId }) else {
                    return
                }
                Self.logger.debug("👨‍🔧 Handle audio track active state change \(sourceId), \(active)")
                source.isAudioActive = active
                self.sources = self.makeSources()
            }
            .store(in: &subscriptions)

        videoTrackStateUpdateSubject
            .sink { [weak self] sourceId, active in
                guard let self, let source = self.partialSources.first(where: { $0.sourceId == sourceId }) else {
                    return
                }
                Self.logger.debug("👨‍🔧 Handle video track active state change \(sourceId), \(active)")
                source.isVideoActive = active
                self.sources = self.makeSources()
            }
            .store(in: &subscriptions)
    }

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
        sources = makeSources()
    }

    func reset() {
        partialSources.removeAll()
        subscriptions.removeAll()
        inactiveVideoSources = []
        inactiveAudioSources = []

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

    // swiftlint:disable cyclomatic_complexity function_body_length
    func observeTrackEvents(for source: StreamSource) {
        Task { [weak self] in
            guard let self else { return }

            var tasks: [Task<Void, Never>] = []
            if let audioTrack = source.audioTrack, self.videoTrackActivityObservationDictionary[source.sourceId] == nil {
                Self.logger.debug("👨‍🔧 Registering for audio track lifecycle events of \(source.sourceId)")
                let audioTrackActivityObservation = Task {
                    for await activityEvent in audioTrack.activity() {
                        switch activityEvent {
                        case .active:
                            Self.logger.debug("👨‍🔧 Audio track for \(source.sourceId) is active")
                            self.inactiveAudioSources.remove(source.sourceId)
                            self.audioTrackStateUpdateSubject.send((source.sourceId, true))

                        case .inactive:
                            Self.logger.debug("👨‍🔧 Audio track for \(source.sourceId) is inactive")
                            self.inactiveAudioSources.insert(source.sourceId)
                            self.audioTrackStateUpdateSubject.send((source.sourceId, false))
                        }
                    }
                }
                self.audioTrackActivityObservationDictionary[source.sourceId] = audioTrackActivityObservation
                tasks.append(audioTrackActivityObservation)
            }

            if self.videoTrackActivityObservationDictionary[source.sourceId] == nil {
                Self.logger.debug("👨‍🔧 Registering for video track lifecycle events of \(source.sourceId)")
                let videoTrackActivityObservation = Task {
                    for await activityEvent in source.videoTrack.activity() {
                        switch activityEvent {
                        case .active:
                            Self.logger.debug("👨‍🔧 Video track for \(source.sourceId) is active")
                            self.inactiveVideoSources.remove(source.sourceId)
                            self.videoTrackStateUpdateSubject.send((source.sourceId, true))
                            
                        case .inactive:
                            Self.logger.debug("👨‍🔧 Video track for \(source.sourceId) is inactive")
                            self.inactiveVideoSources.insert(source.sourceId)
                            self.videoTrackStateUpdateSubject.send((source.sourceId, false))
                        }
                    }
                }
                self.videoTrackActivityObservationDictionary[source.sourceId] = videoTrackActivityObservation
                tasks.append(videoTrackActivityObservation)
            }
            
            await withTaskGroup(of: Void.self) { group in
                for task in tasks {
                    group.addTask { await task.value }
                }
            }
        }
    }
    
    func makeSources() -> [StreamSource] {
        partialSources.compactMap { $0.source }
    }
}

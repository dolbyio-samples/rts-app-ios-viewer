//
//  SubscriptionManager.swift
//

import Foundation
import MillicastSDK
import os
import AVFAudio

protocol SubscriptionManagerProtocol: AnyObject {

    var state: AsyncStream<MCSubscriber.State> { get }
    var statsReport: AsyncStream<MCStatsReport> { get }
    var activityStream: AsyncStream<MCSubscriber.ActivityEvent> { get }
    var tracks: AsyncStream<TrackEvent> { get }
    var layers: AsyncStream<LayersEvent> { get }
    var viewerCount: AsyncStream<Int32> { get }

    static func makeSubscriptionManager(configuration: SubscriptionConfiguration) -> Self

    func connect(streamName: String, accountID: String) async throws -> Bool
    func subscribe() async throws -> Bool
    func unubscribeAndDisconnect() async throws -> Bool
    func addRemoteTrack(_ sourceBuilder: StreamSourceBuilder) async
    func projectVideo(for source: StreamSource, withQuality quality: VideoQuality) async throws
    func unprojectVideo(for source: StreamSource) async throws
    func projectAudio(for source: StreamSource) async throws
    func unprojectAudio(for source: StreamSource) async throws
}

final class SubscriptionManager: SubscriptionManagerProtocol {

    private enum Defaults {
        static let productionSubscribeURL = "https://director.millicast.com/api/director/subscribe"
        static let developmentSubscribeURL = "https://director-dev.millicast.com/api/director/subscribe"
    }

    private static let logger = Logger.make(category: String(describing: SubscriptionManager.self))

    lazy var state: AsyncStream<MCSubscriber.State> = subscriber.state()

    lazy var statsReport: AsyncStream<MCStatsReport> = subscriber.statsReport()

    lazy var activityStream: AsyncStream<MCSubscriber.ActivityEvent> = subscriber.activity()

    lazy var tracks: AsyncStream<TrackEvent> = subscriber.tracks()

    lazy var layers: AsyncStream<LayersEvent> = subscriber.layers()

    lazy var viewerCount: AsyncStream<Int32> = subscriber.viewerCount()

    private let configuration: SubscriptionConfiguration
    private let subscriber: MCSubscriber

    static func makeSubscriptionManager(configuration: SubscriptionConfiguration) -> Self {
        Self.init(configuration: configuration)
    }

    init(configuration: SubscriptionConfiguration) {
        self.configuration = configuration
        self.subscriber = MCSubscriber()
    }

    func connect(streamName: String, accountID: String) async throws -> Bool {
        Self.logger.debug("💼 Connect with streamName & accountID")

        guard streamName.count > 0, accountID.count > 0 else {
            Self.logger.error("💼 Invalid credentials passed to connect")
            return false
        }

        let isConnected = await subscriber.isConnected
        let isSubscribed = await subscriber.isSubscribed

        guard !isSubscribed, !isConnected else {
            Self.logger.error("💼 Subscriber has already connected or subscribed")
            return false
        }

        let credentials = makeCredentials(streamName: streamName, accountID: accountID, useDevelopmentServer: configuration.useDevelopmentServer)

        try await subscriber.setCredentials(credentials)

        let connectionOptions = MCConnectionOptions()
        connectionOptions.autoReconnect = configuration.autoReconnect

        try await subscriber.connect(with: connectionOptions)

        Self.logger.debug("💼 Connect successful")
        return true
    }

    func subscribe() async throws -> Bool {
        Self.logger.debug("💼 Start subscribe")

        let isConnected = await subscriber.isConnected

        guard isConnected else {
            Self.logger.error("💼 Subscriber hasn't completed connect to start subscribe")
            return false
        }

        let isSubscribed = await subscriber.isSubscribed
        guard !isSubscribed else {
            Self.logger.error("💼 Subscriber has already subscribed")
            return false
        }

        let options = MCClientOptions()
        options.videoJitterMinimumDelayMs = Int32(configuration.videoJitterMinimumDelayInMs)
        options.statsDelayMs = Int32(configuration.statsDelayMs)
        if let rtcEventLogOutputPath = configuration.rtcEventLogPath {
            options.rtcEventLogOutputPath = rtcEventLogOutputPath
        }
        options.disableAudio = configuration.disableAudio
        options.forcePlayoutDelay = configuration.noPlayoutDelay

        await subscriber.enableStats(configuration.enableStats)
        try await subscriber.subscribe(with: options)

        Self.logger.debug("💼 Subscribe successful")
        return true
    }

    func unubscribeAndDisconnect() async throws -> Bool {
        Self.logger.debug("💼 Stop subscribe")

        await subscriber.enableStats(false)
        try await subscriber.unsubscribe()
        try await subscriber.disconnect()

        return true
    }

    func addRemoteTrack(_ sourceBuilder: StreamSourceBuilder) async {
        Self.logger.debug("💼 Add remote track for source - \(sourceBuilder.sourceId), \(sourceBuilder.supportedTrackItems)")

        await withThrowingTaskGroup(
            of: (Void).self
        ) { [self] group in
            for trackItem in sourceBuilder.supportedTrackItems {
                group.addTask {
                    Self.logger.debug("💼 Add remote track for media type - \(trackItem.mediaType.rawValue)")
                    try await self.subscriber.addRemoteTrack(trackItem.mediaType.rawValue)
                }
            }
        }
    }

    func projectVideo(for source: StreamSource, withQuality quality: VideoQuality) async throws {
        let videoTrack = source.videoTrack
        let matchingVideoQuality = source.lowLevelVideoQualityList.matching(videoQuality: quality)

        Self.logger.debug("💼 Project video for source \(source.sourceId) with quality - \(String(describing: matchingVideoQuality?.description))")

        let projectionData = MCProjectionData()
        projectionData.media = videoTrack.trackInfo.mediaType.rawValue
        projectionData.mid = videoTrack.trackInfo.mid
        projectionData.trackId = videoTrack.trackInfo.trackID
        projectionData.layer = matchingVideoQuality?.layerData

        try await subscriber.project(source.sourceId.value ?? "", withData: [projectionData])
    }

    func unprojectVideo(for source: StreamSource) async throws {
        Self.logger.debug("💼 Unproject video for source \(source.sourceId)")
        let videoTrack = source.videoTrack
        try await subscriber.unproject([videoTrack.trackInfo.mid])
    }

    func projectAudio(for source: StreamSource) async throws {
        Self.logger.debug("💼 Project audio for source \(source.sourceId)")
        guard let audioTrack = source.audioTracks.first else {
            return
        }

        let projectionData = MCProjectionData()
        audioTrack.track.enable(true)
        audioTrack.track.setVolume(1)
        projectionData.media = audioTrack.trackInfo.mediaType.rawValue
        projectionData.mid = audioTrack.trackInfo.mid
        projectionData.trackId = audioTrack.trackInfo.trackID

        try await subscriber.project(source.sourceId.value ?? "", withData: [projectionData])
    }

    func unprojectAudio(for source: StreamSource) async throws {
        Self.logger.debug("💼 Unproject audio for source \(source.sourceId)")
        guard let audioTrack = source.audioTracks.first else {
            return
        }

        try await subscriber.unproject([audioTrack.trackInfo.mid])
    }
}

// MARK: Maker functions

private extension SubscriptionManager {

    static func makeSubscriber(with configuration: SubscriptionConfiguration) -> MCSubscriber? {
        let subscriber = MCSubscriber()
        return subscriber
    }

    func makeCredentials(streamName: String, accountID: String, useDevelopmentServer: Bool) -> MCSubscriberCredentials {
        let credentials = MCSubscriberCredentials()
        credentials.accountId = accountID
        credentials.streamName = streamName
        credentials.token = ""
        credentials.apiUrl = useDevelopmentServer ? Defaults.developmentSubscribeURL : Defaults.productionSubscribeURL

        return credentials
    }
}

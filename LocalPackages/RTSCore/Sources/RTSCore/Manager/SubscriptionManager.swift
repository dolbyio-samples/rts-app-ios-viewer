//
//  SubscriptionManager.swift
//

import Combine
import Foundation
import MillicastSDK
import os
import SwiftUI

public actor SubscriptionManager: ObservableObject {
    private static let logger = Logger(
        subsystem: Bundle.module.bundleIdentifier!,
        category: String(describing: SubscriptionManager.self)
    )

    public struct ConnectionError: Error, Equatable {
        public let status: NSNumber
        public let reason: String
    }

    public enum State: Equatable {
        case subscribed(sources: [StreamSource])
        case error(ConnectionError)
        case disconnected
    }

    @Published public var state: State = .disconnected
    @Published public var streamStatistics: StreamStatistics?

    private var subscriber: MCSubscriber?
    private var sourceBuilder = SourceBuilder()
    private let logHandler: MillicastLogHandler = .init()

    private var subscriberEventObservationTasks: [Task<Void, Never>] = []

    // MARK: Subscribe API methods

    public init() {
        // Configure the AVAudioSession with our settings.
        AVAudioSession.configure()
    }

    public func subscribe(streamName: String, accountID: String, token: String? = nil, configuration: SubscriptionConfiguration = SubscriptionConfiguration()) async throws {
        let subscriber = MCSubscriber()
        self.subscriber = subscriber
        logHandler.setLogFilePath(filePath: configuration.sdkLogPath)

        Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            await self.registerToSubscriberEvents()
        }

        let subscribeTask = Task(priority: .high) {  [weak subscriber] in
            guard let subscriber else { return }
            Self.logger.debug("👨‍🔧 Start a new connect request")
            let isConnected = await subscriber.isConnected()
            let isSubscribed = await subscriber.isSubscribed()

            guard !isSubscribed, !isConnected else {
                Self.logger.debug("👨‍🔧 Returning as the subscriber is already subscribed or connected")
                throw "Returning as the subscriber is already subscribed or connected"
            }

            let credentials = MCSubscriberCredentials()
            credentials.accountId = accountID
            credentials.streamName = streamName
            credentials.token = token ?? ""
            credentials.apiUrl = configuration.subscribeAPI
            
            try await subscriber.setCredentials(credentials)

            let connectionOptions = MCConnectionOptions()
            connectionOptions.autoReconnect = configuration.autoReconnect
            try await subscriber.connect(with: connectionOptions)
            Self.logger.debug("👨‍🔧 Connection successful")

            let clientOptions = MCClientOptions()
            clientOptions.jitterMinimumDelayMs = Int32(configuration.jitterMinimumDelayMs)
            clientOptions.statsDelayMs = Int32(configuration.statsDelayMs)
            if let rtcEventLogOutputPath = configuration.rtcEventLogPath {
                clientOptions.rtcEventLogOutputPath = rtcEventLogOutputPath
            }
            clientOptions.disableAudio = configuration.disableAudio
            clientOptions.forcePlayoutDelay = configuration.playoutDelay

            await subscriber.enableStats(configuration.enableStats)
            try await subscriber.subscribe(with: clientOptions)
            Self.logger.debug("👨‍🔧 Subscribe successful")
        }
        try await subscribeTask.value
    }

    public func unSubscribe() async throws {
        guard let subscriber else {
            throw "No subscriber instance is present"
        }

        Self.logger.debug("👨‍🔧 Stop subscription")
        await subscriber.enableStats(false)
        try await subscriber.unsubscribe()
        try await subscriber.disconnect()
        Self.logger.debug("👨‍🔧 Successfully stopped subscription")

        reset()
    }

    private func reset() {
        state = .disconnected
        deregisterToSubscriberEvents()
        sourceBuilder.reset()
        subscriber = nil
        logHandler.setLogFilePath(filePath: nil)
    }
}

// MARK: Observations

extension SubscriptionManager {

    // swiftlint:disable function_body_length
    func registerToSubscriberEvents() async {
        guard let subscriber else {
            return
        }
        Self.logger.debug("👨‍🔧 Register to subscriber events")

        let taskWebsocketStateObservation = Task {
            for await state in subscriber.websocketState() {
                Self.logger.debug("👨‍🔧 Websocket connection state changed to \(state.rawValue)")
            }
        }

        let taskPeerConnectionStateObservation = Task {
            for await state in subscriber.peerConnectionState() {
                Self.logger.debug("👨‍🔧 Peer connection state changed to \(state.rawValue)")
            }
        }

        let streamStoppedStateObservation = Task {
            for await state in subscriber.streamStopped() {
                guard !Task.isCancelled else { return }
                Self.logger.debug("👨‍🔧 Stream stopped \(state.description)")
            }
        }

        let taskHttpErrorStateObservation = Task {
            for await state in subscriber.httpError() {
                guard !Task.isCancelled else { return }
                Self.logger.debug("👨‍🔧 Http error state changed to \(state.code), reason: \(state.reason)")
                updateState(to: .error(ConnectionError(status: state.code, reason: state.reason)))
            }
        }

        let taskSignalingErrorStateObservation = Task {
            for await state in subscriber.signalingError() {
                guard !Task.isCancelled else { return }
                Self.logger.debug("👨‍🔧 Signalling error state: reason - \(state.reason)")
            }
        }

        let tracksObservation = Task {
            for await track in subscriber.rtsRemoteTrackAdded() {
                guard !Task.isCancelled else { return }
                Self.logger.debug("👨‍🔧 Remote track added - \(track.sourceID)")
                sourceBuilder.addTrack(track)
            }
        }

        let statsObservation = Task {
            for await statsReport in subscriber.statsReport() {
                guard !Task.isCancelled, let stats = StreamStatistics(statsReport) else {
                    return
                }
                updateStats(stats)
            }
        }

        let sourcesObservation = Task {
            for await sources in sourceBuilder.sourceStream {
                guard !Task.isCancelled else { return }
                Self.logger.debug("👨‍🔧 Sources builder emitted \(sources)")
                updateState(to: .subscribed(sources: sources))
            }
        }

        [
            taskWebsocketStateObservation, taskPeerConnectionStateObservation, taskHttpErrorStateObservation, taskSignalingErrorStateObservation,
            streamStoppedStateObservation, tracksObservation, statsObservation, sourcesObservation
        ].forEach(addEventObservationTask)

        Self.logger.debug("👨‍🔧 Registered to subscriber events")
        _ = await [
            taskWebsocketStateObservation.value,
            taskPeerConnectionStateObservation.value,
            taskHttpErrorStateObservation.value,
            taskSignalingErrorStateObservation.value,
            streamStoppedStateObservation.value,
            tracksObservation.value,
            statsObservation.value,
            sourcesObservation.value
        ]
    }
    // swiftlint:enable function_body_length

    func deregisterToSubscriberEvents() {
        Self.logger.debug("👨‍🔧 Deregister to subscriber events")
        subscriberEventObservationTasks.forEach {
            $0.cancel()
        }
        subscriberEventObservationTasks.removeAll()
    }
}

// MARK: Private Helpers

private extension SubscriptionManager {
    func updateStats(_ stats: StreamStatistics) {
        streamStatistics = stats
    }

    func updateState(to state: State) {
        self.state = state
    }

    func addEventObservationTask(_ task: Task<Void, Never>) {
        subscriberEventObservationTasks.append(task)
    }
}

// MARK: Helper to throw plain string as errors
extension String: Error { }

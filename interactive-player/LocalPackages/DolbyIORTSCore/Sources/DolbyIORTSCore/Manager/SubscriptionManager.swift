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

    public enum SubscriptionError: Error, Equatable {
        case signalingError(reason: String)
        case connectError(status: NSNumber, reason: String)
    }

    public enum State: Equatable {
        case subscribed(sources: [StreamSource])
        case error(SubscriptionError)
        case stopped
        case disconnected
    }

    @Published public var state: State = .disconnected
    @Published public var streamStatistics: StreamStatistics?

    private enum Defaults {
        static let productionSubscribeURL = "https://director.millicast.com/api/director/subscribe"
        static let developmentSubscribeURL = "https://director-dev.millicast.com/api/director/subscribe"
    }

    private var subscriber: MCSubscriber?
    private var sourceBuilder = SourceBuilder()
    private let logHandler: MillicastLoggerHandler = .init()

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

        registerToSubscriberEvents()

        Self.logger.debug("Start a new connect request")
        let isConnected = await subscriber.isConnected()
        let isSubscribed = await subscriber.isSubscribed()

        guard !isSubscribed, !isConnected else {
            Self.logger.debug("Returning as the subscriber is already subscribed or connected")
            throw "Returning as the subscriber is already subscribed or connected"
        }

        try await subscriber.setCredentials(makeCredentials(
            streamName: streamName,
            accountID: accountID,
            token: token ?? "",
            useDevelopmentServer: configuration.useDevelopmentServer)
        )

        let connectionOptions = MCConnectionOptions()
        connectionOptions.autoReconnect = configuration.autoReconnect
        try await subscriber.connect(with: connectionOptions)
        Self.logger.debug("Connection successful")

        let playoutDelay: MCForcePlayoutDelay?
        if let minPlayoutDelay = configuration.minPlayoutDelay, let maxPlayoutDelay = configuration.maxPlayoutDelay {
            playoutDelay = MCForcePlayoutDelay(min: Int32(minPlayoutDelay), max: Int32(maxPlayoutDelay))
        } else {
            playoutDelay = nil
        }

        let clientOptions = MCClientOptions()
        clientOptions.jitterMinimumDelayMs = Int32(configuration.jitterMinimumDelayMs)
        clientOptions.statsDelayMs = Int32(configuration.statsDelayMs)
        if let rtcEventLogOutputPath = configuration.rtcEventLogPath {
            clientOptions.rtcEventLogOutputPath = rtcEventLogOutputPath
        }
        clientOptions.disableAudio = configuration.disableAudio
        clientOptions.forcePlayoutDelay = playoutDelay

        await subscriber.enableStats(configuration.enableStats)
        try await subscriber.subscribe(with: clientOptions)
        Self.logger.debug("Subscription successful")
    }

    public func unSubscribe() async throws {
        guard let subscriber else {
            throw "No subscriber instance is present"
        }

        Self.logger.debug("Stop subscription")
        await subscriber.enableStats(false)
        try await subscriber.unsubscribe()
        try await subscriber.disconnect()
        Self.logger.debug("Successfully stopped subscription")

        state = .disconnected
        deregisterToSubscriberEvents()
        reset()
    }

    private func reset() {
        sourceBuilder.reset()
        subscriber = nil
        logHandler.setLogFilePath(filePath: nil)
    }
}

// MARK: Observations

extension SubscriptionManager {

    // swiftlint:disable function_body_length
    func registerToSubscriberEvents() {
        Task { [weak self] in
            guard
                let self,
                let subscriber = await self.subscriber
            else {
                return
            }

            let taskWebsocketStateObservation = Task {
                for await state in subscriber.websocketState() {
                    Self.logger.debug("Websocket connection state changed to \(state.rawValue)")
                }
            }

            let taskPeerConnectionStateObservation = Task {
                for await state in subscriber.peerConnectionState() {
                    Self.logger.debug("Peer connection state changed to \(state.rawValue)")
                }
            }

            let streamStoppedStateObservation = Task {
                for await state in subscriber.streamStopped() {
                    Self.logger.debug("Stream stopped \(state.description)")
                    await self.updateState(to: .stopped)
                }
            }

            let taskHttpErrorStateObservation = Task {
                for await state in subscriber.httpError() {
                    Self.logger.debug("Http error state changed to \(state.code), reason: \(state.reason)")
                    await self.updateState(to: .error(.connectError(status: state.code, reason: state.reason)))
                }
            }

            let taskSignalingErrorStateObservation = Task {
                for await state in subscriber.signalingError() {
                    Self.logger.debug("Signalling error state: reason - \(state.reason)")
                    await self.updateState(to: .error(.signalingError(reason: state.reason)))
                }
            }

            let tracksObservation = Task {
                for await track in subscriber.rtsRemoteTrackAdded() {
                    Self.logger.debug("Remote track added - \(track.sourceID)")
                    await self.sourceBuilder.addTrack(track)
                }
            }

            let statsObservation = Task {
                for await statsReport in subscriber.statsReport() {
                    guard let stats = StreamStatistics(statsReport) else {
                        return
                    }
                    await self.updateStats(stats)
                }
            }

            let sourcesObservation = Task {
                for await sources in await self.sourceBuilder.sourceStream {
                    Self.logger.debug("Sources builder emitted \(sources)")
                    await self.updateState(to: .subscribed(sources: sources))
                }
            }

            _ = await [
                self.addEventObservationTask(taskWebsocketStateObservation),
                self.addEventObservationTask(taskPeerConnectionStateObservation),
                self.addEventObservationTask(taskHttpErrorStateObservation),
                self.addEventObservationTask(taskSignalingErrorStateObservation),
                self.addEventObservationTask(streamStoppedStateObservation),
                self.addEventObservationTask(tracksObservation),
                self.addEventObservationTask(statsObservation),
                self.addEventObservationTask(sourcesObservation),
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
    }
    // swiftlint:enable function_body_length

    func deregisterToSubscriberEvents() {
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

private extension SubscriptionManager {
    var clientOptions: MCClientOptions {
        let optionsSub = MCClientOptions()
        optionsSub.statsDelayMs = 1000

        return optionsSub
    }

    func makeCredentials(streamName: String, accountID: String, token: String, useDevelopmentServer: Bool) -> MCSubscriberCredentials {
        let credentials = MCSubscriberCredentials()
        credentials.accountId = accountID
        credentials.streamName = streamName
        credentials.token = token
        credentials.apiUrl = useDevelopmentServer ? Defaults.developmentSubscribeURL : Defaults.productionSubscribeURL

        return credentials
    }
}

// MARK: Helper to throw plain string as errors
extension String: Error { }

// MARK: Helper to compare layers by encoding id
extension MCRTSRemoteVideoTrackLayer: Comparable {
   public static func < (lhs: MCRTSRemoteVideoTrackLayer, rhs: MCRTSRemoteVideoTrackLayer) -> Bool {
       switch (lhs.encodingId?.lowercased(), rhs.encodingId?.lowercased()) {
       case ("h", "m"), ("l", "m"), ("h", "s"), ("l", "s"), ("m", "s"):
           return false
       default:
           return true
       }
   }
}

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
        case subscribed(sources: [Source])
        case error(SubscriptionError)
        case disconnected
    }

    @Published public var state: State = .disconnected
    @Published public var statistics: StatisticsReport?

    private enum Defaults {
        static let productionSubscribeURL = "https://director.millicast.com/api/director/subscribe"
        static let developmentSubscribeURL = "https://director-dev.millicast.com/api/director/subscribe"
    }

    private var subscriber: MCSubscriber?
    private var sourceBuilder = SourceBuilder()
    private let logHandler: MillicastLoggerHandler = .init()

    private var subscriberEventObservationTasks: [Task<Void, Never>] = []
    private var sourceSubscription: AnyCancellable?

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

        let clientOptions = MCClientOptions()
        clientOptions.jitterMinimumDelayMs = Int32(configuration.jitterMinimumDelayMs)
        clientOptions.statsDelayMs = Int32(configuration.statsDelayMs)
        if let rtcEventLogOutputPath = configuration.rtcEventLogPath {
            clientOptions.rtcEventLogOutputPath = rtcEventLogOutputPath
        }
        clientOptions.disableAudio = configuration.disableAudio
        clientOptions.forcePlayoutDelay = configuration.forcePlayoutDelay

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

    // swiftlint:disable cyclomatic_complexity function_body_length
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
                    await self.sourceBuilder.addTrack(track)
                }
            }

            let statsObservation = Task {
                for await statsReport in subscriber.statsReport() {
                    guard let stats = StatisticsReport(report: statsReport) else {
                        return
                    }
                    await self.updateStats(stats)
                }
            }

            let cancellable = await self.sourceBuilder.sourcePublisher
                .sink { source in
                    Task {
                        await self.updateState(to: .subscribed(sources: source))
                    }
                }

            _ = await [
                self.addEventObservationTask(taskWebsocketStateObservation),
                self.addEventObservationTask(taskPeerConnectionStateObservation),
                self.addEventObservationTask(taskHttpErrorStateObservation),
                self.addEventObservationTask(taskSignalingErrorStateObservation),
                self.addEventObservationTask(tracksObservation),
                self.addEventObservationTask(statsObservation),
                self.updateSourceSubscription(cancellable),
                taskWebsocketStateObservation.value,
                taskPeerConnectionStateObservation.value,
                taskHttpErrorStateObservation.value,
                taskSignalingErrorStateObservation.value,
                tracksObservation.value,
                statsObservation.value
            ]
        }
    }
    // swiftlint:enable cyclomatic_complexity function_body_length

    func deregisterToSubscriberEvents() {
        subscriberEventObservationTasks.removeAll()
        sourceSubscription = nil
    }
}

// MARK: Private Helpers

private extension SubscriptionManager {
    func updateStats(_ stats: StatisticsReport) {
        statistics = stats
    }

    func updateState(to state: State) {
        self.state = state
    }

    func addEventObservationTask(_ task: Task<Void, Never>) {
        subscriberEventObservationTasks.append(task)
    }

    func updateSourceSubscription(_ subscription: AnyCancellable) {
        sourceSubscription = subscription
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

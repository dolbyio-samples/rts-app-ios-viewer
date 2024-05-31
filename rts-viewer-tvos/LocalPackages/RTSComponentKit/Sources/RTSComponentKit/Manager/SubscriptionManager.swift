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
        case connectError(status: Int32, reason: String)
    }

    public enum State: Equatable {
        case subscribed(sources: [Source])
        case stopped
        case error(SubscriptionError)
    }

    @Published public var state: State = .stopped
    @Published public var statistics: StatisticsReport?

    private var subscriber: MCSubscriber?
    private var sourceBuilder = SourceBuilder()

    private var subscriberEventObservationTasks: [Task<Void, Never>] = []
    private var sourceSubscription: AnyCancellable?

    // MARK: Subscribe API methods

    public init() {
        // Configure the AVAudioSession with our settings.
        AVAudioSession.configure()
    }

    public func subscribe(streamName: String, accountID: String) async throws {
        let subscriber = MCSubscriber()
        self.subscriber = subscriber

        registerToSubscriberEvents()

        Self.logger.debug("Start a new connect request")
        let isConnected = await subscriber.isConnected()
        let isSubscribed = await subscriber.isSubscribed()

        guard !isSubscribed, !isConnected else {
            Self.logger.debug("Returning as the subscriber is already subscribed or connected")
            throw "Returning as the subscriber is already subscribed or connected"
        }

        try await subscriber.setCredentials(makeCredentials(streamName: streamName, accountID: accountID))
        try await subscriber.connect()
        Self.logger.debug("Connection successful")

        await subscriber.enableStats(true)
        try await subscriber.subscribe()
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

        deregisterToSubscriberEvents()
        reset()
    }

    private func reset() {
        sourceBuilder.reset()
        subscriber = nil
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

            let taskStateObservation = Task {
                for await state in subscriber.state() {
                    switch state {
                    case .connected:
                        // No-op
                        break

                    case .disconnected:
                        await self.updateState(to: .stopped)

                    case .subscribed:
                        switch await self.state {
                        case .subscribed:
                            // No-op, preserve the current subscribed state
                            break
                        default:
                            await self.updateState(to: .subscribed(sources: []))
                        }

                    case let .connectionError(status: status, reason: reason):
                        await self.updateState(to: .error(.connectError(status: status, reason: reason)))

                    case .signalingError(reason: let reason):
                        await self.updateState(to: .error(.signalingError(reason: reason)))
                    }
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
                self.addEventObservationTask(taskStateObservation),
                self.addEventObservationTask(tracksObservation),
                self.addEventObservationTask(statsObservation),
                self.updateSourceSubscription(cancellable),
                taskStateObservation.value,
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

    func makeCredentials(streamName: String, accountID: String) -> MCSubscriberCredentials {
        let credentials = MCSubscriberCredentials()
        credentials.apiUrl = "https://director.millicast.com/api/director/subscribe"
        credentials.accountId = accountID
        credentials.streamName = streamName
        credentials.token = ""

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

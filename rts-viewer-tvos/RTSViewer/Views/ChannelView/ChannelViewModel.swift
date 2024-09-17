//
//  ChannelViewModel.swift
//

import Combine
import Foundation
import MillicastSDK
import os
import RTSCore
import SwiftUI

@MainActor
final class ChannelViewModel: ObservableObject {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: ChannelViewModel.self)
    )

    @Binding var unsourcedChannels: [UnsourcedChannel]?
    @Published private(set) var state: State = .loading

    private let onClose: () -> Void
    private let serialTasks = SerialTasks()
    private var subscriptions: [AnyCancellable] = []
    private var reconnectionTimer: Timer?
    private var isWebsocketConnected: Bool = false

    private var sourcedChannels: [Channel] = []

    enum State {
        case loading
        case success(channels: [Channel])
        case error(title: String, subtitle: String?, showLiveIndicator: Bool)
    }

    init(unsourcedChannels: Binding<[UnsourcedChannel]?>, onClose: @escaping () -> Void) {
        self._unsourcedChannels = unsourcedChannels
        self.onClose = onClose
        startObservers()
    }

    @objc func viewStreams() {
        guard let unsourcedChannels else { return }
        for unsourcedChannel in unsourcedChannels {
            viewStream(with: unsourcedChannel)
        }
    }

    func viewStream(with unsourcedChannel: UnsourcedChannel) {
        Task(priority: .userInitiated) {
            let subscriptionManager = unsourcedChannel.subscriptionManager
            let configuration = SubscriptionConfiguration(subscribeAPI: unsourcedChannel.streamConfig.apiUrl)
            _ = try await subscriptionManager.subscribe(
                streamName: unsourcedChannel.streamConfig.streamName,
                accountID: unsourcedChannel.streamConfig.accountId,
                configuration: configuration
            )
        }
    }

    func endStream() {
        Task(priority: .userInitiated) { [weak self] in
            guard let self,
                  let unsourcedChannels else { return }
            for unsourcedChannel in unsourcedChannels {
                self.subscriptions.removeAll()
                self.reconnectionTimer?.invalidate()
                self.reconnectionTimer = nil
                _ = try await unsourcedChannel.subscriptionManager.unSubscribe()
            }
            onClose()
        }
    }

    func scheduleReconnection() {
        Self.logger.debug("🎰 Schedule reconnection")
        reconnectionTimer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(viewStreams), userInfo: nil, repeats: false)
    }

    private func update(state: State) {
        self.state = state
    }
}

private extension ChannelViewModel {
    // swiftlint:disable function_body_length cyclomatic_complexity
    func startObservers() {
        Task { [weak self] in
            guard let self,
                  let unsourcedChannels else { return }

            for unsourcedChannel in unsourcedChannels {
                await unsourcedChannel.subscriptionManager.$state
                    .sink { state in
                        Self.logger.debug("🎰 State and settings events")
                        Task {
                            try await self.serialTasks.enqueue {
                                switch state {
                                case let .subscribed(sources: sources):
                                    let activeSources = Array(sources.filter { $0.videoTrack.isActive == true })
                                    let soundSources = Array(activeSources.filter { $0.audioTrack?.isActive == true })

                                    guard !soundSources.isEmpty else { return }
                                    await self.updateChannelWithSources(unsourcedChannel: unsourcedChannel, sources: soundSources)

                                    guard !Task.isCancelled else { return }

                                case .disconnected:
                                    await Self.logger.debug("🎰 Stream disconnected")
                                    await self.update(state: .loading)

                                case let .error(connectionError) where connectionError.status == 0:
                                    // Status code `0` represents a `no network error`
                                    await Self.logger.debug("🎰 No internet connection")
                                    if await !self.isWebsocketConnected {
                                        await self.scheduleReconnection()
                                    }
                                    await self.update(
                                        state: .error(
                                            title: .noInternetErrorTitle,
                                            subtitle: nil,
                                            showLiveIndicator: false
                                        )
                                    )

                                case let .error(connectionError):
                                    await Self.logger.debug("🎰 Connection error - \(connectionError.status), \(connectionError.reason)")

                                    if await !self.isWebsocketConnected {
                                        await self.scheduleReconnection()
                                    }
                                }
                            }
                        }
                    }
                    .store(in: &subscriptions)

                await unsourcedChannel.subscriptionManager.$websocketState
                    .sink { websocketState in
                        switch websocketState {
                        case .connected:
                            self.isWebsocketConnected = true
                        default:
                            break
                        }
                    }
                    .store(in: &subscriptions)
            }
        }
    }
    // swiftlint:enable function_body_length cyclomatic_complexity

    // TODO: Should be reworked when we have streams with a single source with audio
    func updateChannelWithSources(unsourcedChannel: UnsourcedChannel, sources: [StreamSource]) {
        guard !sourcedChannels.contains(where: { $0.id == unsourcedChannel.id }),
              sources.count > 0 else { return }
        let sourcedChannel = Channel(unsourcedChannel: unsourcedChannel, source: sources[0])
        sourcedChannels.append(sourcedChannel)

        update(state: .success(channels: sourcedChannels))
    }
}

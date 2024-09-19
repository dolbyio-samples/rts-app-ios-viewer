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

    @Binding var channels: [Channel]?
    @Published private(set) var state: State = .loading
    let onClose: () -> Void
    private let serialTasks = SerialTasks()
    private var sourcedChannels: [SourcedChannel] = []
    private var stateObservation: Task<Void, Never>?
    private var subscriptions = [AnyCancellable]()
    private var isWebsocketConnected: Bool = false
    private var reconnectionTimer: Timer?

    enum State {
        case loading
        case success(channels: [SourcedChannel], isPlayingAudio: Bool)
        case error(title: String, subtitle: String?, showLiveIndicator: Bool)
    }

    init(channels: Binding<[Channel]?>, onClose: @escaping () -> Void) {
        self._channels = channels
        self.onClose = onClose

        Task(priority: .userInitiated) { [weak self] in
            await self?.startObservers()
        }
    }

    @objc func viewStreams() {
        guard let channels else { return }
        for channel in channels {
            viewStream(for: channel)
        }
    }

    func viewStream(for channel: Channel) {
        Task(priority: .userInitiated) {
            let subscriptionManager = channel.subscriptionManager
            _ = try await subscriptionManager.subscribe(streamName: channel.streamDetail.streamName,
                                                        accountID: channel.streamDetail.accountID)
        }
    }

    func endStreams() {
        Task(priority: .userInitiated) { [weak self] in
            guard let self,
                  let channels else { return }
            for channel in channels {
                self.subscriptions.removeAll()
//                self.reconnectionTimer?.invalidate()
//                self.reconnectionTimer = nil
//                await channel.videoTracksManager.reset()
                _ = try await channel.subscriptionManager.unSubscribe()
            }
            onClose()
        }
    }
}

private extension ChannelViewModel {
    // swiftlint:disable function_body_length cyclomatic_complexity
    private func setupStateObservers() async {
        stateObservation = Task(priority: .userInitiated) { [weak self] in
            guard let self = self,
                let channels else { return }
            for channel in channels {
                await channel.subscriptionManager.$state
                    .sink { state in
                        Task {
                            guard !Task.isCancelled else { return }
                            switch state {
                            case let .subscribed(sources: sources):
                                let activeVideoSources = sources.filter { $0.videoTrack.isActive }
                                Self.logger.debug("🎰 Subscribed, has \(activeVideoSources.count) active video sources")
                                guard let videoSource = activeVideoSources.first(where: { $0.sourceId == .main }) else {
//                                    self.state = .streamNotPublished(
//                                        title: LocalizedStringKey("stream.offline.title.label").toString(),
//                                        subtitle: LocalizedStringKey("stream.offline.subtitle.label").toString(),
//                                        source: nil
//                                    )
//                                    self.clearLayerInformation()
                                    return
                                }
                                
                                Task(priority: .userInitiated) {
                                    guard !Task.isCancelled else { return }
                                    
                                    await self.observeLayerEvents(for: videoSource)
                                }
                                
                                Task(priority: .high) {
                                    guard
                                        !Task.isCancelled,
                                        videoSource.videoTrack.isActive
                                    else {
                                        return
                                    }
                                    
                                    try await self.serialTasks.enqueue {
                                        switch await self.state {
                                        case let .streaming(source: currentSource, playingAudio: isPlayingAudio):
                                            // No-action needed, already viewing stream
                                            Self.logger.debug("🎰 Already viewing source \(currentSource.sourceId)")
                                            if !isPlayingAudio {
                                                if let audioTrack = videoSource.audioTrack, audioTrack.isActive {
                                                    Self.logger.debug("🎰 Picked source \(videoSource.sourceId) for audio")
                                                    // Enable new audio track
                                                    try await audioTrack.enable()
                                                    await MainActor.run {
                                                        self.state = .streaming(source: videoSource, playingAudio: true)
                                                    }
                                                }
                                            }
                                        default:
                                            Self.logger.debug("🎰 Picked source \(videoSource.sourceId)")
                                            
                                            let renderer = await MainActor.run {
                                                self.rendererRegistry.acceleratedRenderer(for: videoSource)
                                            }
                                            try await videoSource.videoTrack.enable(renderer: renderer.underlyingRenderer, promote: true)
                                            Self.logger.debug("🎰 Picked source \(videoSource.sourceId) for video")
                                            await self.storeProjectedMid(for: videoSource)
                                            
                                            let isPlayingAudio: Bool
                                            if let audioTrack = videoSource.audioTrack, audioTrack.isActive {
                                                Self.logger.debug("🎰 Picked source \(videoSource.sourceId) for audio")
                                                // Enable new audio track
                                                try await audioTrack.enable()
                                                isPlayingAudio = true
                                            } else {
                                                isPlayingAudio = false
                                            }
                                            
                                            await MainActor.run {
                                                self.state = .streaming(source: videoSource, playingAudio: isPlayingAudio)
                                            }
                                        }
                                    }
                                }
                                
                            case .disconnected:
                                Self.logger.debug("🎰 Disconnected")
                                guard !Task.isCancelled else { return }
                                
                                self.state = .disconnected
                                
                            case let .error(connectionError) where connectionError.status == 0:
                                Self.logger.debug("🎰 No internet connection")
                                guard !Task.isCancelled else { return }
                                
                                if !self.isWebsocketConnected {
                                    self.scheduleReconnection()
                                }
                                
                                self.state = .noNetwork(
                                    title: LocalizedStringKey("stream.network.disconnected.label").toString()
                                )
                                
                            case let .error(connectionError):
                                Self.logger.debug("🎰 Connection error - \(connectionError.status), \(connectionError.reason)")
                                guard !Task.isCancelled else { return }
                                
                                if !self.isWebsocketConnected {
                                    self.scheduleReconnection()
                                }
                                
                                self.state = .streamNotPublished(
                                    title: LocalizedStringKey("stream.offline.title.label").toString(),
                                    subtitle: LocalizedStringKey("stream.offline.subtitle.label").toString(),
                                    source: nil
                                )
                            }
                        }
                    }
                    .store(in: &subscriptions)
                
                await self.subscriptionManager.$websocketState
                    .receive(on: DispatchQueue.main)
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
            await stateObservation?.value
        }
    }

    // swiftlint:enable function_body_length cyclomatic_complexity

    func updateChannelWithSources(channel: Channel, sources: [StreamSource]) {
        guard !sourcedChannels.contains(where: { $0.id == channel.id }),
              sources.count > 0 else { return }
        let sourcedChannel = SourcedChannel.build(from: channel, source: sources[0])
        sourcedChannels.append(sourcedChannel)

        print("$$$ subscription success")
        update(state: .success(channels: sourcedChannels, isPlayingAudio: <#Bool#>))
    }

    func scheduleReconnection() {
        Self.logger.debug("🎰 Schedule reconnection")
        reconnectionTimer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(viewStreams), userInfo: nil, repeats: false)
    }

    func update(state: State) {
        self.state = state
    }

    func storeProjectedMid(for source: StreamSource) {
        guard let mid = source.videoTrack.currentMID else {
            return
        }
        projectedMids.insert(mid)
    }

    func removeProjectedMid(for source: StreamSource) {
        guard let mid = source.videoTrack.currentMID else {
            return
        }
        projectedMids.remove(mid)
    }
}

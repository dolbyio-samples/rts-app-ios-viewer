//
//  StatsInfoViewModel.swift
//

import Combine
import Foundation
import RTSCore

@MainActor
final class StatsInfoViewModel: ObservableObject {
    @Published private(set) var statsItems: [StatsItem] = []
    @Published private(set) var targetBitrate: String = "N/A"
    @Published private(set) var outgoingBitrate: String = "N/A"
    @Published private(set) var subscriberId: String = "N/A"
    @Published private(set) var streamId: String = "N/A"
    private let subscriptionManager: SubscriptionManager
    private let videoTracksManager: VideoTracksManager
    private let streamSource: StreamSource
    private var subscriptions: [AnyCancellable] = []

    init(
        streamSource: StreamSource,
        videoTracksManager: VideoTracksManager,
        subscriptionManager: SubscriptionManager
    ) {
        self.streamSource = streamSource
        self.videoTracksManager = videoTracksManager
        self.subscriptionManager = subscriptionManager

        Task {
            self.statsItems = await subscriptionManager.streamStatistics.map { Self.makeStatsItems(for: $0, streamSource: streamSource) } ?? []
            let sourcedBitrates = await videoTracksManager.sourcedBitrates
            guard let sourcedBitrate = sourcedBitrates[streamSource.sourceId] else { return }
            if let target = sourcedBitrate.targetBitrate {
                self.targetBitrate = Self.formatBitRate(bitRate: target)
            }
            if let bitrate = sourcedBitrate.bitrate {
                self.outgoingBitrate = Self.formatBitRate(bitRate: bitrate)
            }
        }

        observeStats()
    }

    struct StatsItem: Identifiable {
        var id: String { key }
        var key: String
        var value: String
    }

    private func observeStats() {
        Task { [weak self] in
            guard let self else { return }
            await self.subscriptionManager.$streamStatistics
                .receive(on: DispatchQueue.main)
                .sink { [weak self] statistics in
                    guard let self else { return }
                    self.statsItems = statistics.map { Self.makeStatsItems(for: $0, streamSource: self.streamSource) } ?? []
                }
                .store(in: &subscriptions)

            await self.videoTracksManager.$sourcedBitrates
                .receive(on: DispatchQueue.main)
                .sink { [weak self] sourcedBitrates in
                    guard let self else { return }
                    if let sourcedBitrate = sourcedBitrates[streamSource.sourceId] {
                        if let target = sourcedBitrate.targetBitrate {
                            self.targetBitrate = Self.formatBitRate(bitRate: target)
                        } else {
                            self.targetBitrate = "N/A"
                        }
                        if let bitrate = sourcedBitrate.bitrate {
                            self.outgoingBitrate = Self.formatBitRate(bitRate: bitrate)
                        } else {
                            self.outgoingBitrate = "N/A"
                        }
                    }
                }
                .store(in: &subscriptions)
        }
    }
}

private extension StatsInfoViewModel {
    // swiftlint:disable function_body_length
    // swiftlint:disable cyclomatic_complexity
    static func makeStatsItems(for streamStatistics: StreamStatistics, streamSource: StreamSource) -> [StatsItem] {
        guard
            let mid = streamSource.videoTrack.currentMID,
            let videoStatsInboundRtp = streamStatistics.inboundVideoStatistics(matching: mid)
        else {
            return []
        }

        let audioStatsInboundRtp = streamStatistics.inboundAudioStatistics(matching: mid)

        var result = [StatsItem]()

        if let streamViewId = streamStatistics.streamViewId {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.stream-view-id.label"),
                    value: streamViewId
                )
            )
        }

        if let subscriberId = streamStatistics.subscriberId {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.subscriber-id.label"),
                    value: subscriberId
                )
            )
        }

        if let clusterId = streamStatistics.clusterId {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.cluster-id.label"),
                    value: clusterId
                )
            )
        }

        if let mid = videoStatsInboundRtp.mid {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.mid.label"),
                    value: mid
                )
            )
        }

        if let decoderImplementation = videoStatsInboundRtp.decoder {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.decoder-impl.label"),
                    value: String(decoderImplementation)
                )
            )
        }

        let processingDelay = videoStatsInboundRtp.processingDelay
        result.append(
            StatsItem(
                key: String(localized: "stream.stats.processing-delay.label"),
                value: String(format: "%.2f ms", processingDelay)
            )
        )

        let decodeTime = videoStatsInboundRtp.decodeTime
        result.append(
            StatsItem(
                key: String(localized: "stream.stats.decode-time.label"),
                value: String(format: "%.2f ms", decodeTime)
            )
        )

        let videoResolution = videoStatsInboundRtp.videoResolution
        result.append(
            StatsItem(
                key: String(localized: "stream.stats.video-resolution.label"),
                value: videoResolution
            )
        )

        let fps = videoStatsInboundRtp.fps
        result.append(
            StatsItem(
                key: String(localized: "stream.stats.fps.label"),
                value: String(fps)
            )
        )

        let videoBytesReceived = videoStatsInboundRtp.bytesReceived
        result.append(
            StatsItem(
                key: String(localized: "stream.stats.video-total-received.label"),
                value: formatBytes(bytes: videoBytesReceived)
            )
        )

        if let audioBytesReceived = audioStatsInboundRtp?.bytesReceived {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.audio-total-received.label"),
                    value: formatBytes(bytes: audioBytesReceived)
                )
            )
        }

        let packetsReceived = videoStatsInboundRtp.packetsReceived
        result.append(
            StatsItem(
                key: String(localized: "stream.stats.packets-received.label"),
                value: String(packetsReceived)
            )
        )

        let framesDecoded = videoStatsInboundRtp.framesDecoded
        result.append(
            StatsItem(
                key: String(localized: "stream.stats.frames-decoded.label"),
                value: String(framesDecoded)
            )
        )

        let framesDropped = videoStatsInboundRtp.framesDropped
        if framesDropped > 0 {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.frames-dropped.label"),
                    value: String(framesDropped)
                )
            )
        }

        let jitterBufferEmittedCount = videoStatsInboundRtp.jitterBufferEmittedCount
        result.append(
            StatsItem(
                key: String(localized: "stream.stats.jitter-buffer-est-count.label"),
                value: String(jitterBufferEmittedCount)
            )
        )

        let videoJitter = videoStatsInboundRtp.jitter
        result.append(
            StatsItem(
                key: String(localized: "stream.stats.video-jitter.label"),
                value: "\(videoJitter) ms"
            )
        )

        if let audioJitter = audioStatsInboundRtp?.jitter {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.audio-jitter.label"),
                    value: "\(audioJitter) ms"
                )
            )
        }

        let jitterBufferDelay = videoStatsInboundRtp.jitterBufferDelay
        result.append(
            StatsItem(
                key: String(localized: "stream.stats.jitter-buffer-delay.label"),
                value: String(format: "%.2f ms", jitterBufferDelay)
            )
        )

        let jitterBufferTargetDelay = videoStatsInboundRtp.jitterBufferTargetDelay
        result.append(
            StatsItem(
                key: String(localized: "stream.stats.jitter-buffer-target-delay.label"),
                value: String(format: "%.2f ms", jitterBufferTargetDelay)
            )
        )

        let jitterBufferMinimumDelay = videoStatsInboundRtp.jitterBufferMinimumDelay
        result.append(
            StatsItem(
                key: String(localized: "stream.stats.jitter-buffer-minimum-delay.label"),
                value: String(format: "%.2f ms", jitterBufferMinimumDelay)
            )
        )

        let videoPacketsLost = videoStatsInboundRtp.packetsLost
        if videoPacketsLost > 0 {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.video-packet-loss.label"),
                    value: String(videoPacketsLost)
                )
            )
        }

        if let audioPacketsLost = audioStatsInboundRtp?.packetsLost,
           audioPacketsLost > 0 {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.audio-packet-loss.label"),
                    value: String(audioPacketsLost)
                )
            )
        }

        let freezeCount = videoStatsInboundRtp.freezeCount
        if freezeCount > 0 {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.freeze-count.label"),
                    value: String(freezeCount)
                )
            )
        }

        let freezeDuration = videoStatsInboundRtp.freezeDuration
        if freezeDuration > 0 {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.freeze-duration.label"),
                    value: String(format: "%.2f ms", freezeDuration)
                )
            )
        }

        let pauseCount = videoStatsInboundRtp.pauseCount
        if pauseCount > 0 {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.pause-count.label"),
                    value: String(pauseCount)
                )
            )
        }

        let pauseDuration = videoStatsInboundRtp.pauseDuration
        if pauseDuration > 0 {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.pause-duration.label"),
                    value: String(format: "%.2f ms", pauseDuration)
                )
            )
        }

        if let videoStatsOutboundRtp = streamStatistics.outboundVideoStatistics() {
            let retransmittedPackets = videoStatsOutboundRtp.retransmittedPackets
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.retransmitted-packets.label"),
                    value: String(retransmittedPackets)
                )
            )

            let retransmittedBytes = videoStatsOutboundRtp.retransmittedBytes
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.retransmitted-bytes.label"),
                    value: String(retransmittedBytes)
                )
            )
        }

        if let currentRtt = streamStatistics.currentRoundTripTime {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.current-rtt.label"),
                    value: String(currentRtt)
                )
            )
        }

        if let totalRtt = streamStatistics.totalRoundTripTime {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.total-rtt.label"),
                    value: String(totalRtt)
                )
            )
        }

        let timestamp = videoStatsInboundRtp.timestamp
        result.append(
            StatsItem(
                key: String(localized: "stream.stats.timestamp.label"),
                value: dateString(timestamp / 1000)
            )
        )

        let totalTime = videoStatsInboundRtp.totalTime
        result.append(
            StatsItem(
                key: String(localized: "stream.stats.total-stream-time.label"),
                value: elapsedTimeString(totalTime / 1000)
            )
        )

        let audioCodec = audioStatsInboundRtp?.codecName
        let videoCodec = videoStatsInboundRtp.codecName
        if audioCodec != nil || videoCodec != nil {
            var delimiter = ", "
            if audioCodec == nil || videoCodec == nil {
                delimiter = ""
            }
            let codecs = "\(audioCodec ?? "")\(delimiter)\(videoCodec ?? "")"
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.codecs.label"),
                    value: codecs
                )
            )
        }

        let incomingBitrate = videoStatsInboundRtp.incomingBitrate
        result.append(
            StatsItem(
                key: String(localized: "stream.stats.incoming-bitrate.label"),
                value: formatBitRate(bitRate: Int(incomingBitrate))
            )
        )

        return result
    }

    // swiftlint:enable function_body_length
    // swiftlint:enable cyclomatic_complexity

    static func dateString(_ timestamp: Double) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"

        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        return dateFormatter.string(from: date)
    }

    static func elapsedTimeString(_ timestamp: Double) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "HH:mm:ss"

        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        return dateFormatter.string(from: date)
    }

    static func formatBytes(bytes: Int) -> String {
        return "\(formatNumber(input: bytes))B"
    }

    static func formatBitRate(bitRate: Int) -> String {
        let value = formatNumber(input: bitRate).lowercased()
        return "\(value)bps"
    }

    static func formatNumber(input: Int) -> String {
        if input < KILOBYTES { return String(input) }
        if input >= KILOBYTES && input < MEGABYTES { return "\(input / KILOBYTES) K" } else { return "\(input / MEGABYTES) M" }
    }
}

private let KILOBYTES = 1024
private let MEGABYTES = KILOBYTES * KILOBYTES

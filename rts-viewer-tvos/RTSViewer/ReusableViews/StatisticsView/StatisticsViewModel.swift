//
//  StatisticsViewModel.swift
//

import Combine
import Foundation
import RTSCore
import UIKit
import SwiftUI

@MainActor
final class StatisticsViewModel: ObservableObject {

    struct StatsItem: Identifiable {
        var id: String { key }
        var key: String
        var value: String
    }

    private let source: StreamSource
    private let subscriptionManager: SubscriptionManager
    private var subscriptions: [AnyCancellable] = []

    @Published private(set) var statsDataList: [StatsItem] = []

    init(source: StreamSource, subscriptionManager: SubscriptionManager) {
        self.source = source
        self.subscriptionManager = subscriptionManager

        Task { [weak self] in
            guard let self else { return }
            let subscription = await subscriptionManager.$streamStatistics
                .sink { statisticsReport in
                    guard let statisticsReport else { return }
                    Task {
                        await MainActor.run {
                            self.statsDataList = self.makeStatsList(from: statisticsReport)
                        }
                    }
                }
            self.store(subscription: subscription)
        }
    }

    private func store(subscription: AnyCancellable) {
        subscriptions.append(subscription)
    }
}

// MARK: Stats report parsing
private extension StatisticsViewModel {

    // swiftlint:disable function_body_length
    func makeStatsList(from streamStatistics: StreamStatistics) -> [StatsItem] {
        var result = [StatsItem]()
        guard
            let mid = source.videoTrack.currentMID,
            let videoStatsInboundRtp = streamStatistics.videoStatistics(matching: mid)
        else {
            return []
        }
        let audioStatsInboundRtp = streamStatistics.audioStatistics(matching: mid)

        result.append(
            StatsItem(
                key: String(localized: "stream.stats.mid.label"),
                value: videoStatsInboundRtp.mid
            )
        )

        if let decoderImplementation = videoStatsInboundRtp.decoderImplementation {
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
        result.append(
            StatsItem(
                key: String(localized: "stream.stats.frames-dropped.label"),
                value: String(framesDropped)
            )
        )

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
        result.append(
            StatsItem(
                key: String(localized: "stream.stats.video-packet-loss.label"),
                value: String(videoPacketsLost)
            )
        )

        if let audioPacketsLost = audioStatsInboundRtp?.packetsLost {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.audio-packet-loss.label"),
                    value: String(audioPacketsLost)
                )
            )
        }

        if let rtt = streamStatistics.roundTripTime {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.rtt.label"),
                    value: String(rtt)
                )
            )
        }
        if let timestamp = audioStatsInboundRtp?.timestamp {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.timestamp.label"),
                    value: dateString(timestamp: timestamp / 1000)
                )
            )
        }
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
        return result
    }
    // swiftlint:enable function_body_length

    func dateString(timestamp: Double) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"

        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        return dateFormatter.string(from: date)
    }

    func formatBytes(bytes: Int) -> String {
        return "\(formatNumber(input: bytes))B"
    }

    func formatBitRate(bitRate: Int) -> String {
        let value = formatNumber(input: bitRate).lowercased()
        return "\(value)bps"
    }

    func formatNumber(input: Int) -> String {
        if input < KILOBYTES { return String(input) }
        if input >= KILOBYTES && input < MEGABYTES { return "\(input / KILOBYTES) K"} else { return "\(input / MEGABYTES) M" }
    }
}

private let KILOBYTES = 1024
private let MEGABYTES = KILOBYTES * KILOBYTES

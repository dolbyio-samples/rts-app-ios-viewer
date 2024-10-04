//
//  StatisticsViewModel.swift
//

import Combine
import Foundation
import MillicastSDK
import RTSCore
import SwiftUI
import UIKit

final class StatisticsViewModel: ObservableObject {
    struct StatsItem: Identifiable {
        var id: String { key }
        var key: String
        var value: String
    }

    private let source: StreamSource
    let statsItems: [StatsItem]

    init(
        source: StreamSource,
        streamStatistics: MCSubscriberStats,
        layers: [MCRTSRemoteTrackLayer],
        projectedTimeStamp: Double?,
        isMultiChannel: Bool = false
    ) {
        self.source = source
        statsItems = Self.makeStatsList(
            from: source,
            streamStatistics: streamStatistics,
            layers: layers,
            projectedTimeStamp: projectedTimeStamp,
            isMultiChannel: isMultiChannel
        )
    }
}

// MARK: Stats report parsing

private extension StatisticsViewModel {
    // swiftlint:disable function_body_length cyclomatic_complexity
    static func makeStatsList(
        from source: StreamSource,
        streamStatistics: MCSubscriberStats,
        layers: [MCRTSRemoteTrackLayer],
        projectedTimeStamp: Double?,
        isMultiChannel: Bool = false
    ) -> [StatsItem] {
        var result = [StatsItem]()
        let videoTrackStats = streamStatistics.trackStats.first(where: { $0.mid == source.videoTrack.currentMID })
        let audioTrackStats = streamStatistics.trackStats.first(where: { $0.mid == source.audioTrack?.currentMID })

        result.append(
            StatsItem(
                key: String(localized: "stream.stats.stream-view-id.label"),
                value: streamStatistics.streamViewId
            )
        )

        result.append(
            StatsItem(
                key: String(localized: "stream.stats.subscriber-id.label"),
                value: streamStatistics.subscriberId
            )
        )

        result.append(
            StatsItem(
                key: String(localized: "stream.stats.cluster-id.label"),
                value: streamStatistics.clusterId
            )
        )

        if let mid = videoTrackStats?.mid {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.mid.label"),
                    value: mid
                )
            )
        }

        if let decoderImplementation = videoTrackStats?.decoderImplementation {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.decoder-impl.label"),
                    value: decoderImplementation
                )
            )
        }

        if let processingDelay = videoTrackStats?.processingDelay {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.processing-delay.label"),
                    value: String(format: "%.2f ms", processingDelay.doubleValue * 1000)
                )
            )
        }

        if let decodeTime = videoTrackStats?.decodeTime {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.decode-time.label"),
                    value: String(format: "%.2f ms", decodeTime.doubleValue * 1000)
                )
            )
        }

        if let frameWidth = videoTrackStats?.frameWidth, let frameHeight = videoTrackStats?.frameHeight {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.video-resolution.label"),
                    value: "\(frameWidth) x \(frameHeight)"
                )
            )
        }

        if let fps = videoTrackStats?.framesPerSecond {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.fps.label"),
                    value: "\(fps.intValue)"
                )
            )
        }

        if let videoBytesReceived = videoTrackStats?.bytesReceived {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.video-total-received.label"),
                    value: formatBytes(bytes: videoBytesReceived.intValue)
                )
            )
        }

        if let audioBytesReceived = audioTrackStats?.bytesReceived {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.audio-total-received.label"),
                    value: formatBytes(bytes: audioBytesReceived.intValue)
                )
            )
        }

        if let packetsReceived = videoTrackStats?.packetsReceived {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.packets-received.label"),
                    value: "\(packetsReceived.intValue)"
                )
            )
        }

        if let framesDecoded = videoTrackStats?.framesDecoded {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.frames-decoded.label"),
                    value: "\(framesDecoded.intValue)"
                )
            )
        }

        if let framesDropped = videoTrackStats?.framesDropped?.intValue {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.frames-dropped.label"),
                    value: "\(framesDropped)"
                )
            )
        }

        if let videoJitter = videoTrackStats?.jitter {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.video-jitter.label"),
                    value: String(format: "%.2f ms", videoJitter.doubleValue * 1000)
                )
            )
        }

        if let audioJitter = audioTrackStats?.jitter {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.audio-jitter.label"),
                    value: String(format: "%.2f ms", audioJitter.doubleValue * 1000)
                )
            )
        }

        if let jitterBufferDelay = videoTrackStats?.jitterBufferDelay {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.jitter-buffer-delay.label"),
                    value: String(format: "%.2f ms", jitterBufferDelay.doubleValue * 1000)
                )
            )
        }

        if let jitterBufferMinimumDelay = videoTrackStats?.jitterBufferMinimumDelay {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.jitter-buffer-minimum-delay.label"),
                    value: String(format: "%.2f ms", jitterBufferMinimumDelay.doubleValue * 1000)
                )
            )
        }

        if let videoPacketsLost = videoTrackStats?.packetsLost?.intValue {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.video-packet-loss.label"),
                    value: "\(videoPacketsLost)"
                )
            )
        }

        if let audioPacketsLost = audioTrackStats?.packetsLost?.intValue {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.audio-packet-loss.label"),
                    value: "\(audioPacketsLost)"
                )
            )
        }

        if let freezeCount = videoTrackStats?.freezeCount?.intValue {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.freeze-count.label"),
                    value: String(freezeCount)
                )
            )
        }

        if let freezeDuration = videoTrackStats?.totalFreezeDuration?.doubleValue {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.freeze-duration.label"),
                    value: String(format: "%.2f ms", freezeDuration * 1000)
                )
            )
        }

        if let pauseCount = videoTrackStats?.pauseCount?.intValue {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.pause-count.label"),
                    value: "\(pauseCount)"
                )
            )
        }

        if let pauseDuration = videoTrackStats?.totalPauseDuration?.doubleValue {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.pause-duration.label"),
                    value: String(format: "%.2f ms", pauseDuration * 1000)
                )
            )
        }

        if let retransmittedPackets = videoTrackStats?.retransmittedPacketsReceived?.intValue {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.retransmitted-packets.label"),
                    value: "\(retransmittedPackets)"
                )
            )
        }

        if let retransmittedBytesReceived = videoTrackStats?.retransmittedBytesReceived?.intValue {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.retransmitted-bytes.label"),
                    value: "\(retransmittedBytesReceived)"
                )
            )
        }

        if let currentRTT = streamStatistics.currentRoundTripTime {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.current-rtt.label"),
                    value: String(format: "%.2f ms", currentRTT.doubleValue * 1000)
                )
            )
        }

        if let totalRTT = streamStatistics.totalRoundTripTime {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.total-rtt.label"),
                    value: String(format: "%.2f ms", totalRTT.doubleValue * 1000)
                )
            )
        }

        let timestamp = streamStatistics.timestamp
        result.append(
            StatsItem(
                key: String(localized: "stream.stats.timestamp.label"),
                value: dateString(timestamp / 1000)
            )
        )

        if let projectedTimeStamp {
            let totalTime = streamStatistics.timestamp - projectedTimeStamp
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.total-stream-time.label"),
                    value: elapsedTimeString(totalTime / 1000)
                )
            )
        }

        let audioCodec = audioTrackStats?.mimeType
        let videoCodec = videoTrackStats?.mimeType
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

        if let bitrate = videoTrackStats?.bitrateBps {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.incoming-bitrate.label"),
                    value: formatBitRate(bitRate: bitrate.doubleValue)
                )
            )
        }

        if let frameWidth = videoTrackStats?.frameWidth?.intValue,
           let frameHeight = videoTrackStats?.frameHeight?.intValue,
           let selectedLayer = layers.first(where: { frameWidth == ($0.resolution?.width ?? 0) && frameHeight == ($0.resolution?.height ?? 0)}) {
            if let targetBitrate = selectedLayer.targetBitrate {
                result.append(
                    StatsItem(
                        key: String(localized: "stream.stats.target-bitrate.label"),
                        value: Self.formatBitRate(bitRate: targetBitrate.doubleValue)
                    )
                )
            } else {
                result.append(
                    StatsItem(
                        key: String(localized: "stream.stats.target-bitrate.label"),
                        value: "N/A"
                    )
                )
            }

            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.outgoing-bitrate.label"),
                    value: Self.formatBitRate(bitRate: Double(selectedLayer.bitrate))
                )
            )
        } else {
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.target-bitrate.label"),
                    value: "N/A"
                )
            )

            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.outgoing-bitrate.label"),
                    value: "N/A"
                )
            )
        }

        return result
    }

    // swiftlint:enable function_body_length cyclomatic_complexity

    static func dateString(_ timestamp: Double) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"

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

    static func formatBitRate(bitRate: Double) -> String {
        if bitRate < KILOBITS {
            "\(bitRate) bps"
        } else if bitRate >= KILOBITS && bitRate < MEGABITS {
            "\((bitRate / KILOBITS).rounded(toPlaces: 4)) Kbps"
        } else {
            "\((bitRate / MEGABITS).rounded(toPlaces: 4)) Mbps"
        }
    }

    static func formatNumber(input: Int) -> String {
        if input < KILOBYTES { return String(input) }
        if input >= KILOBYTES && input < MEGABYTES { return "\(input / KILOBYTES) K" } else { return "\(input / MEGABYTES) M" }
    }
}

private let KILOBYTES = 1024
private let MEGABYTES = KILOBYTES * KILOBYTES

private let KILOBITS: Double = 1000
private let MEGABITS = KILOBITS * KILOBITS

private extension Double {
    /// Rounds the double to decimal places value
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

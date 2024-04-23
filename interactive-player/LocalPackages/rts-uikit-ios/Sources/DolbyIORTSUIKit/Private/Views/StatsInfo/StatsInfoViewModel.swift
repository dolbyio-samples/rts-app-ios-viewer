//
//  StatsInfoViewModel.swift
//

import Combine
import DolbyIORTSCore
import Foundation

final class StatsInfoViewModel: ObservableObject {
    private let streamSource: StreamSource

    init(streamSource: StreamSource) {
        self.streamSource = streamSource
    }

    struct StatData: Identifiable {
        var id = UUID()
        var key: String
        var value: String
    }

    var data: [StatData] {
        guard let stats = streamSource.streamingStatistics else {
            return []
        }

        var result = [StatData]()

        if let mid = stats.videoStatsInboundRtp?.mid {
            result.append(
                StatData(
                    key: String(localized: "stream.stats.mid.label", bundle: .module),
                    value: String(mid)
                )
            )
        }
        if let decoderImplementation = stats.videoStatsInboundRtp?.decoderImplementation {
            result.append(
                StatData(
                    key: String(localized: "stream.stats.decoder-impl.label", bundle: .module),
                    value: String(decoderImplementation)
                )
            )
        }
        if let processingDelay = stats.videoStatsInboundRtp?.processingDelay {
            result.append(
                StatData(
                    key: String(localized: "stream.stats.processing-delay.label", bundle: .module),
                    value: String(format: "%.2f ms", processingDelay)
                )
            )
        }
        if let decodeTime = stats.videoStatsInboundRtp?.decodeTime {
            result.append(
                StatData(
                    key: String(localized: "stream.stats.decode-time.label", bundle: .module),
                    value: String(format: "%.2f ms", decodeTime)
                )
            )
        }
        if let videoResolution = stats.videoStatsInboundRtp?.videoResolution {
            result.append(
                StatData(
                    key: String(localized: "stream.stats.video-resolution.label", bundle: .module),
                    value: videoResolution
                )
            )
        }
        if let fps = stats.videoStatsInboundRtp?.fps {
            result.append(
                StatData(
                    key: String(localized: "stream.stats.fps.label", bundle: .module),
                    value: String(fps)
                )
            )
        }
        if let videoBytesReceived = stats.videoStatsInboundRtp?.bytesReceived {
            result.append(
                StatData(
                    key: String(localized: "stream.stats.video-total-received.label", bundle: .module),
                    value: formatBytes(bytes: videoBytesReceived)
                )
            )
        }
        if let audioBytesReceived = stats.audioStatsInboundRtp?.bytesReceived {
            result.append(
                StatData(
                    key: String(localized: "stream.stats.audio-total-received.label", bundle: .module),
                    value: formatBytes(bytes: audioBytesReceived)
                )
            )
        }
        if let packetsReceived = stats.videoStatsInboundRtp?.packetsReceived {
            result.append(
                StatData(
                    key: String(localized: "stream.stats.packets-received.label", bundle: .module),
                    value: String(packetsReceived)
                )
            )
        }
        if let framesDecoded = stats.videoStatsInboundRtp?.framesDecoded {
            result.append(
                StatData(
                    key: String(localized: "stream.stats.frames-decoded.label", bundle: .module),
                    value: String(framesDecoded)
                )
            )
        }
        if let framesDropped = stats.videoStatsInboundRtp?.framesDropped {
            result.append(
                StatData(
                    key: String(localized: "stream.stats.frames-dropped.label", bundle: .module),
                    value: String(framesDropped)
                )
            )
        }
        if let jitterBufferEmittedCount = stats.videoStatsInboundRtp?.jitterBufferEmittedCount {
            result.append(
                StatData(
                    key: String(localized: "stream.stats.jitter-buffer-est-count.label", bundle: .module),
                    value: String(jitterBufferEmittedCount)
                )
            )
        }
        if let videoJitter = stats.videoStatsInboundRtp?.jitter {
            result.append(
                StatData(
                    key: String(localized: "stream.stats.video-jitter.label", bundle: .module),
                    value: "\(videoJitter) ms"
                )
            )
        }
        if let audioJitter = stats.audioStatsInboundRtp?.jitter {
            result.append(
                StatData(
                    key: String(localized: "stream.stats.audio-jitter.label", bundle: .module),
                    value: "\(audioJitter) ms"
                )
            )
        }
        if let jitterBufferDelay = stats.videoStatsInboundRtp?.jitterBufferDelay {
            result.append(
                StatData(
                    key: String(localized: "stream.stats.jitter-buffer-delay.label", bundle: .module),
                    value: String(format: "%.2f ms", jitterBufferDelay)
                )
            )
        }
        if let jitterBufferTargetDelay = stats.videoStatsInboundRtp?.jitterBufferTargetDelay {
            result.append(
                StatData(
                    key: String(localized: "stream.stats.jitter-buffer-target-delay.label", bundle: .module),
                    value: String(format: "%.2f ms", jitterBufferTargetDelay)
                )
            )
        }
        if let jitterBufferMinimumDelay = stats.videoStatsInboundRtp?.jitterBufferMinimumDelay {
            result.append(
                StatData(
                    key: String(localized: "stream.stats.jitter-buffer-minimum-delay.label", bundle: .module),
                    value: String(format: "%.2f ms", jitterBufferMinimumDelay)
                )
            )
        }
        if let videoPacketsLost = stats.videoStatsInboundRtp?.packetsLost {
            result.append(
                StatData(
                    key: String(localized: "stream.stats.video-packet-loss.label", bundle: .module),
                    value: String(videoPacketsLost)
                )
            )
        }
        if let audioPacketsLost = stats.audioStatsInboundRtp?.packetsLost {
            result.append(
                StatData(
                    key: String(localized: "stream.stats.audio-packet-loss.label", bundle: .module),
                    value: String(audioPacketsLost)
                )
            )
        }
        if let rtt = stats.roundTripTime {
            result.append(
                StatData(
                    key: String(localized: "stream.stats.rtt.label", bundle: .module),
                    value: String(rtt)
                )
            )
        }
        if let timestamp = stats.audioStatsInboundRtp?.timestamp {
            result.append(
                StatData(
                    key: String(localized: "stream.stats.timestamp.label", bundle: .module),
                    value: dateStr(timestamp / 1000)
                )
            )
        }
        let audioCodec = stats.audioStatsInboundRtp?.codecName
        let videoCodec = stats.videoStatsInboundRtp?.codecName
        if audioCodec != nil || videoCodec != nil {
            var delimiter = ", "
            if audioCodec == nil || videoCodec == nil {
                delimiter = ""
            }
            let codecs = "\(audioCodec ?? "")\(delimiter)\(videoCodec ?? "")"
            result.append(
                StatData(
                    key: String(localized: "stream.stats.codecs.label", bundle: .module),
                    value: codecs
                )
            )
        }
        return result
    }

    private func dateStr(_ timestamp: Double) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS'Z'"

        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        return dateFormatter.string(from: date)
    }

    private func formatBytes(bytes: Int) -> String {
        return "\(formatNumber(input: bytes))B"
    }

    private func formatBitRate(bitRate: Int) -> String {
        let value = formatNumber(input: bitRate).lowercased()
        return "\(value)bps"
    }

    private func formatNumber(input: Int) -> String {
        if input < KILOBYTES { return String(input) }
        if input >= KILOBYTES && input < MEGABYTES { return "\(input / KILOBYTES) K"} else { return "\(input / MEGABYTES) M" }
    }
}

private let KILOBYTES = 1024
private let MEGABYTES = KILOBYTES * KILOBYTES

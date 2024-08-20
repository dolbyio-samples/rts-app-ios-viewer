//
//  StatsInfoViewModel.swift
//

import Combine
import Foundation
import MillicastSDK
import RTSCore

@MainActor
final class StatsInfoViewModel: ObservableObject {
    @Published private(set) var statsItems: [StatsItem] = []
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

        Task { [weak self] in
            guard let self else { return }
            let mid = self.streamSource.videoTrack.currentMID
            let layers = await self.videoTracksManager.sourceToSimulcastLayersMapping
            let projectedTimeStampForMids = await self.videoTracksManager.projectedTimeStampForMids
            let projectedTimeStampForSource = mid.map { projectedTimeStampForMids[$0] } ?? nil
            guard let stats = await subscriptionManager.streamStatistics else {
                return
            }

            let layersForSource = layers[self.streamSource.sourceId] ?? []
            self.statsItems = Self.makeStatsItems(
                for: stats,
                streamSource: self.streamSource,
                layers: layersForSource,
                projectedTimeStamp: projectedTimeStampForSource
            )
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
            let streamStatisticsPublisher = await self.subscriptionManager.$streamStatistics
            let layersPublisher = await self.videoTracksManager.layersPublisher

            streamStatisticsPublisher.combineLatest(layersPublisher)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] statistics, layers in
                    Task {
                        guard
                            let self,
                            let stats = statistics
                        else {
                            return
                        }
                        let layersForSource = layers[self.streamSource.sourceId] ?? []
                        let mid = self.streamSource.videoTrack.currentMID
                        let projectedTimeStampForMids = await self.videoTracksManager.projectedTimeStampForMids
                        let projectedTimeStampForSource = mid.map { projectedTimeStampForMids[$0] } ?? nil

                        self.statsItems = Self.makeStatsItems(
                            for: stats,
                            streamSource: self.streamSource,
                            layers: layersForSource,
                            projectedTimeStamp: projectedTimeStampForSource
                        )
                    }
                }
                .store(in: &subscriptions)
        }
    }
}

private extension StatsInfoViewModel {
    // swiftlint:disable function_body_length
    // swiftlint:disable cyclomatic_complexity
    static func makeStatsItems(
        for streamStatistics: StreamStatistics,
        streamSource: StreamSource,
        layers: [MCRTSRemoteTrackLayer],
        projectedTimeStamp: Double?
    ) -> [StatsItem] {
        guard
            let mid = streamSource.videoTrack.currentMID,
            let videoStatsInboundRtp = streamStatistics.inboundVideoStatistics(matching: mid)
        else {
            return []
        }

        let audioStatsInboundRtp = streamStatistics.audioStatsInboundRtpList.first

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

        let freezeCount = videoStatsInboundRtp.freezeCount
        result.append(
            StatsItem(
                key: String(localized: "stream.stats.freeze-count.label"),
                value: String(freezeCount)
            )
        )

        let freezeDuration = videoStatsInboundRtp.freezeDuration
        result.append(
            StatsItem(
                key: String(localized: "stream.stats.freeze-duration.label"),
                value: String(format: "%.2f ms", freezeDuration)
            )
        )

        let pauseCount = videoStatsInboundRtp.pauseCount
        result.append(
            StatsItem(
                key: String(localized: "stream.stats.pause-count.label"),
                value: String(pauseCount)
            )
        )

        let pauseDuration = videoStatsInboundRtp.pauseDuration
        result.append(
            StatsItem(
                key: String(localized: "stream.stats.pause-duration.label"),
                value: String(format: "%.2f ms", pauseDuration)
            )
        )

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

        if let projectedTimeStamp {
            let totalTime = videoStatsInboundRtp.timestamp - projectedTimeStamp
            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.total-stream-time.label"),
                    value: elapsedTimeString(totalTime / 1000)
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

        if let projectedTimeStamp {
            let bitsReceived = videoStatsInboundRtp.bytesReceived * 8
            let totalTimeInSeconds = (videoStatsInboundRtp.timestamp - projectedTimeStamp) / 1000
            let incomingBitRate = Double(bitsReceived) / totalTimeInSeconds

            result.append(
                StatsItem(
                    key: String(localized: "stream.stats.incoming-bitrate.label"),
                    value: formatBitRate(bitRate: incomingBitRate)
                )
            )
        }

        if let selectedLayer = layers.first(where: {
            Int(videoStatsInboundRtp.frameWidth) == ($0.resolution?.width ?? 0)
            && Int(videoStatsInboundRtp.frameHeight) == ($0.resolution?.height ?? 0)
        }) {
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

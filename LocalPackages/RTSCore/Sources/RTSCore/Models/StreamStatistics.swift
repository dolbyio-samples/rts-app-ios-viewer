//
//  StatisticsReport.swift
//

import Foundation
import MillicastSDK

public struct StreamStatistics: Equatable, Hashable {
    public let roundTripTime: Double?
    public var videoStatsInboundRtpList: [StatsInboundRtp]
    public var audioStatsInboundRtpList: [StatsInboundRtp]
}

public struct StatsInboundRtp: Equatable, Hashable {
    public let kind: String?
    public let sid: String?
    public let mid: String?
    public let decoder: String?
    public let processingDelay: Double
    public let decodeTime: Double
    public let frameWidth: Int
    public let frameHeight: Int
    public let fps: Int
    public let audioLevel: Int
    public let totalEnergy: Double
    public let framesReceived: Int
    public let framesDecoded: Int
    public let framesDropped: Int
    public let jitterBufferEmittedCount: Int
    public let jitterBufferDelay: Double
    public let jitterBufferTargetDelay: Double
    public let jitterBufferMinimumDelay: Double
    public let nackCount: Int
    public let bytesReceived: Int
    public let totalSampleDuration: Double
    public let codec: String?
    public let jitter: Double
    public let packetsReceived: Int
    public let packetsLost: Int
    public let timestamp: Double
    public var codecName: String?

    public var videoResolution: String {
        "\(frameWidth) x \(frameHeight)"
    }
}

extension StreamStatistics {
    init?(_ report: MCStatsReport) {
        let receivedType = MCRemoteInboundRtpStreamStats.get_type()
        guard let remoteInboundStreamStatsList = report.getStatsOf(receivedType) as? [MCRemoteInboundRtpStreamStats] else {
            return nil
        }
        roundTripTime = remoteInboundStreamStatsList.first.map { $0.round_trip_time }

        let inboundRtpStreamStatsType = MCInboundRtpStreamStats.get_type()
        guard let inboundRtpStreamStatsList = report.getStatsOf(inboundRtpStreamStatsType) as? [MCInboundRtpStreamStats] else {
           return nil
        }

        let codecType = MCCodecsStats.get_type()
        let codecStatsList = report.getStatsOf(codecType) as? [MCCodecsStats]

        videoStatsInboundRtpList = [StatsInboundRtp]()
        let videos = inboundRtpStreamStatsList
            .filter { $0.kind == "video" }
            .map {
                StatsInboundRtp($0, codecStatsList: codecStatsList)
            }
        videoStatsInboundRtpList.append(contentsOf: videos)

        audioStatsInboundRtpList = [StatsInboundRtp]()
        let audios = inboundRtpStreamStatsList
            .filter { $0.kind == "audio" }
            .map {
                StatsInboundRtp($0, codecStatsList: codecStatsList)
            }
        audioStatsInboundRtpList.append(contentsOf: audios)
    }
}

extension StatsInboundRtp {
    init(_ stats: MCInboundRtpStreamStats, codecStatsList: [MCCodecsStats]?) {
        kind = stats.kind
        sid = stats.sid
        mid = stats.mid
        frameWidth = Int(stats.frame_width)
        frameHeight = Int(stats.frame_height)
        fps = Int(stats.frames_per_second)
        bytesReceived = Int(stats.bytes_received)
        framesReceived = Int(stats.frames_received)
        packetsReceived = Int(stats.packets_received)
        framesDecoded = Int(stats.frames_decoded)
        framesDropped = Int(stats.frames_dropped)
        jitterBufferEmittedCount = Int(stats.jitter_buffer_emitted_count)
        jitter = stats.jitter * 1000
        processingDelay = Self.msNormalised(
            numerator: stats.total_processing_delay,
            denominator: stats.frames_decoded
        )
        decodeTime = Self.msNormalised(
            numerator: stats.total_decode_time,
            denominator: stats.frames_decoded
        )
        jitterBufferDelay = Self.msNormalised(
            numerator: stats.jitter_buffer_delay,
            denominator: stats.jitter_buffer_emitted_count
        )
        jitterBufferTargetDelay = Self.msNormalised(
            numerator: stats.jitter_buffer_target_delay,
            denominator: stats.jitter_buffer_emitted_count
        )
        jitterBufferMinimumDelay = Self.msNormalised(
            numerator: stats.jitter_buffer_minimum_delay,
            denominator: stats.jitter_buffer_emitted_count
        )
        nackCount = Int(stats.nack_count)
        packetsLost = Int(stats.packets_lost)
        decoder = stats.decoder_implementation
        audioLevel = Int(stats.audio_level)
        totalEnergy = stats.total_audio_energy
        totalSampleDuration = stats.total_samples_duration
        codec = stats.codec_id
        timestamp = Double(stats.timestamp)

        if let codecStats = codecStatsList?.first(where: { $0.sid == stats.codec_id }) {
            codecName = codecStats.mime_type
        }
    }

    private static func msNormalised(numerator: Double, denominator: UInt) -> Double {
        denominator == 0 ? 0 : numerator * 1000 / Double(denominator)
    }
}

extension StreamStatistics {
    public func videoStatistics(matching mid: String) -> StatsInboundRtp? {
        self.videoStatsInboundRtpList.first { mid == $0.mid }
    }

    public func audioStatistics(matching mid: String) -> StatsInboundRtp? {
        self.audioStatsInboundRtpList.first { mid == $0.mid }
    }
}

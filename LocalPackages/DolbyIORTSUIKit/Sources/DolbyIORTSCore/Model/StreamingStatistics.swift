//
//  StreamingStatistics.swift
//

import Foundation
import MillicastSDK

public struct StreamingStatistics {
    public let roundTripTime: Double?
    public let audioStatsInboundRtp: StatsInboundRtp?
    public let videoStatsInboundRtp: StatsInboundRtp?

    public struct StatsInboundRtp {
        public let sid: String
        public let kind: String
        public let decoder: String?
        public let frameWidth: Int
        public let frameHeight: Int
        public let fps: Int
        public let audioLevel: Int
        public let totalEnergy: Double
        public let framesReceived: Int
        public let framesDecoded: Int
        public let nackCount: Int
        public let bytesReceived: Int
        public let totalSampleDuration: Double
        public let codec: String?
        public let jitter: Double
        public let packetsReceived: Double
        public let packetsLost: Double
        public let timestamp: Double
        public var codecName: String?

        public var videoResolution: String {
            "\(frameWidth) x \(frameHeight)"
        }
    }
}

extension StreamingStatistics {
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

        videoStatsInboundRtp = inboundRtpStreamStatsList
            .first { $0.kind == "video" }
            .map {
                StatsInboundRtp($0, codecStatsList: codecStatsList)
            }

        audioStatsInboundRtp = inboundRtpStreamStatsList
            .first { $0.kind == "audio" }
            .map {
                StatsInboundRtp($0, codecStatsList: codecStatsList)
            }
    }
}

extension StreamingStatistics.StatsInboundRtp {
    init(_ stats: MCInboundRtpStreamStats, codecStatsList: [MCCodecsStats]?) {
        sid = stats.sid  as String
        kind = stats.kind as String
        decoder = stats.decoder_implementation as String?
        frameWidth = Int(stats.frame_width)
        frameHeight = Int(stats.frame_height)
        fps = Int(stats.frames_per_second)
        audioLevel = Int(stats.audio_level)
        totalEnergy = stats.total_audio_energy
        framesReceived = Int(stats.frames_received)
        framesDecoded = Int(stats.frames_decoded)
        nackCount = Int(stats.nack_count)
        bytesReceived = Int(stats.bytes_received)
        totalSampleDuration = stats.total_samples_duration
        codec = stats.codec_id as String?
        jitter = stats.jitter
        packetsReceived = Double(stats.packets_received)
        packetsLost = Double(stats.packets_lost)
        timestamp = Double(stats.timestamp)

        if let codecStats = codecStatsList?.first(where: { $0.sid == stats.codec_id }) {
            codecName = codecStats.mime_type as String
        } else {
            codecName = nil
        }
    }
}

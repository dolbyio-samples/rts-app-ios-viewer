//
//  StatisticsReport.swift
//

import Foundation
import MillicastSDK

public struct StatisticsReport: Equatable {
    public let roundTripTime: Double?
    public let audio: StatsInboundRtp?
    public let video: StatsInboundRtp?
    init(roundTripTime: Double?, audio: StatsInboundRtp?, video: StatsInboundRtp?) {
        self.roundTripTime = roundTripTime
        self.audio = audio
        self.video = video
    }

    init?(report: MCStatsReport?) {
        let inboundRtpStreamStatsType = MCInboundRtpStreamStats.get_type()
        let rtt: Double? = Self.getStatisticsRoundTripTime(report: report)
        guard let inboundRtpStreamStatsList = report?.getStatsOf(inboundRtpStreamStatsType) as? [MCInboundRtpStreamStats] else {
            return nil
        }
        var audio: StatsInboundRtp?
        var video: StatsInboundRtp?
        for inboundRtpStreamStats in inboundRtpStreamStatsList {
            var codecName: String?
            if let codecId = inboundRtpStreamStats.codec_id as String? {
                codecName = Self.getStatisticsCodec(codecId: codecId, report: report)
            }
            let statsInboundRtp = StatsInboundRtp(
                sid: inboundRtpStreamStats.sid as String,
                kind: inboundRtpStreamStats.kind as String,
                decoder: inboundRtpStreamStats.decoder_implementation as String?,
                frameWidth: Int(inboundRtpStreamStats.frame_width),
                frameHeight: Int(inboundRtpStreamStats.frame_height),
                fps: Int(inboundRtpStreamStats.frames_per_second),
                audioLevel: Int(inboundRtpStreamStats.audio_level),
                totalEnergy: inboundRtpStreamStats.total_audio_energy,
                framesReceived: Int(inboundRtpStreamStats.frames_received),
                framesDecoded: Int(inboundRtpStreamStats.frames_decoded),
                nackCount: Int(inboundRtpStreamStats.nack_count),
                bytesReceived: Int(inboundRtpStreamStats.bytes_received),
                totalSampleDuration: inboundRtpStreamStats.total_samples_duration,
                codecId: inboundRtpStreamStats.codec_id as String?,
                jitter: inboundRtpStreamStats.jitter,
                packetsReceived: Double(inboundRtpStreamStats.packets_received),
                packetsLost: Double(inboundRtpStreamStats.packets_lost),
                timestamp: Double(inboundRtpStreamStats.timestamp),
                codecName: codecName
            )
            if statsInboundRtp.isVideo {
                video = statsInboundRtp
            } else {
                audio = statsInboundRtp
            }
        }
        self.init(roundTripTime: rtt, audio: audio, video: video)
    }

    private static func getStatisticsRoundTripTime(report: MCStatsReport?) -> Double? {
        let receivedType = MCRemoteInboundRtpStreamStats.get_type()
        guard let remoteInboundRtpStreamStatsList = report?.getStatsOf(receivedType) as? [MCRemoteInboundRtpStreamStats] else {
            return nil
        }

        return remoteInboundRtpStreamStatsList.first.map { Double($0.round_trip_time) }
    }

    private static func getStatisticsCodec(codecId: String, report: MCStatsReport?) -> String? {
        let codecType = MCCodecsStats.get_type()
        guard
            let statsReport = report?.getStatsOf(codecType),
            let codecStats = statsReport.first(where: { $0 is MCCodecsStats && $0.sid as String == codecId }) as? MCCodecsStats
        else {
            return nil
        }

        return codecStats.mime_type as String
    }
}

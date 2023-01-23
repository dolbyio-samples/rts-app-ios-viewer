//
//  StatsInboundRtp.swift
//

import Foundation

public struct StatsInboundRtp {
    public let sid: String
    public let kind: String
    public let decoder: String?
    public let frameWidth: Int
    public let frameHeight: Int
    public let videoResolution: String
    public let fps: Int
    public let audioLevel: Int
    public let totalEnergy: Double
    public let framesReceived: Int
    public let framesDecoded: Int
    public let framesBitDepth: Int
    public let nackCount: Int
    public let bytesReceived: Int
    public let totalSampleDuration: Double
    public let codec: String?
    public let jitter: Double
    public let packetsReceived: Double
    public let packetsLost: Double
    public let timestamp: Double
    public var codecName: String?

    public let isVideo: Bool
    init(sid: String, kind: String, decoder: String?, frameWidth: Int, frameHeight: Int, fps: Int, audioLevel: Int, totalEnergy: Double, framesReceived: Int, framesDecoded: Int, framesBitDepth: Int, nackCount: Int, bytesReceived: Int, totalSampleDuration: Double, codecId: String?, jitter: Double, packetsReceived: Double, packetsLost: Double, timestamp: Double, codecName: String?) {

        self.sid = sid
        self.kind = kind
        self.decoder = decoder
        self.frameWidth = frameWidth
        self.frameHeight = frameHeight
        self.fps = fps
        self.audioLevel = audioLevel
        self.totalEnergy = totalEnergy
        self.framesReceived = framesReceived
        self.framesDecoded = framesDecoded
        self.framesBitDepth = framesBitDepth
        self.nackCount = nackCount
        self.bytesReceived = bytesReceived
        self.totalSampleDuration = totalSampleDuration
        self.codec = codecId
        self.codecName = codecName

        self.jitter = jitter
        self.packetsReceived = packetsReceived
        self.packetsLost = packetsLost

        self.timestamp = timestamp

        if kind == "video" {
            isVideo = true
        } else {
            isVideo = false
        }

        self.videoResolution = String(format: "%d x %d", frameWidth, frameHeight)
    }
}

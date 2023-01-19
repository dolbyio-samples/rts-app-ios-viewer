//
//  StatsInboundRtp.swift
//

import Foundation

public struct StatsInboundRtp {
    public private(set) var sid: String
    public private(set) var decoder: String?
    public private(set) var frameWidth: Int
    public private(set) var frameHeight: Int
    public private(set) var videoResolution: String
    public private(set) var fps: Int
    public private(set) var audioLevel: Int
    public private(set) var totalEnergy: Double
    public private(set) var framesReceived: Int
    public private(set) var framesDecoded: Int
    public private(set) var framesBitDepth: Int
    public private(set) var nackCount: Int
    public private(set) var bytesReceived: Int
    public private(set) var totalSampleDuration: Double
    public private(set) var codec: String?
    public private(set) var jitter: Double
    public private(set) var packetsReceived: Double
    public private(set) var packetsLost: Double
    public private(set) var timestamp: Double

    public private(set) var isVideo: Bool
    init(sid: String, decoder: String?, frameWidth: Int, frameHeight: Int, fps: Int, audioLevel: Int, totalEnergy: Double, framesReceived: Int, framesDecoded: Int, framesBitDepth: Int, nackCount: Int, bytesReceived: Int, totalSampleDuration: Double, codecId: String?, jitter: Double, packetsReceived: Double, packetsLost: Double, timestamp: Double) {

        self.sid = sid
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

        self.jitter = jitter
        self.packetsReceived = packetsReceived
        self.packetsLost = packetsLost

        self.timestamp = timestamp

        if sid.starts(with: "RTCInboundRTPVideoStream") {
            isVideo = true
        } else {
            isVideo = false
        }

        self.videoResolution = String(format: "%d x %d", frameWidth, frameHeight)
    }
}

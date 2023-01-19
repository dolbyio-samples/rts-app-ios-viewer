//
//  StatisticsData.swift
//

import Foundation

public struct StatisticsData {
    public private(set) var roundTripTime: Double?
    public private(set) var audio: StatsInboundRtp?
    public private(set) var video: StatsInboundRtp?
    init(roundTripTime: Double?, audio: StatsInboundRtp?, video: StatsInboundRtp?) {
        self.roundTripTime = roundTripTime
        self.audio = audio
        self.video = video
    }
}

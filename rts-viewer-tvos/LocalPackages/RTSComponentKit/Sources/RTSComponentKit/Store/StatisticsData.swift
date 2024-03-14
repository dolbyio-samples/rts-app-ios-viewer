//
//  StatisticsData.swift
//

import Foundation

public struct StatisticsData: Equatable {
    public let roundTripTime: Double?
    public let audio: StatsInboundRtp?
    public let video: StatsInboundRtp?
    init(roundTripTime: Double?, audio: StatsInboundRtp?, video: StatsInboundRtp?) {
        self.roundTripTime = roundTripTime
        self.audio = audio
        self.video = video
    }
}

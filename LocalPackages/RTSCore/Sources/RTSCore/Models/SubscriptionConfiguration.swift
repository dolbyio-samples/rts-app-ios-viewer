//
//  SubscriptionConfiguration.swift
//

import Foundation
import MillicastSDK

public struct SubscriptionConfiguration {
    public enum Constants {
        public static let autoReconnect = true
        public static let jitterMinimumDelayMs: UInt = 20
        public static let statsDelayMs: UInt = 1000
        public static let disableAudio = false
        public static let enableStats = true
        public static let playoutDelay: MCForcePlayoutDelay? = nil
        public static let productionSubscribeURL = "https://director.millicast.com/api/director/subscribe"
        public static let developmentSubscribeURL = "https://director-dev.millicast.com/api/director/subscribe"
    }

    public let subscribeAPI: String
    public let autoReconnect: Bool
    public let jitterMinimumDelayMs: UInt
    public let statsDelayMs: UInt
    public let disableAudio: Bool
    public let rtcEventLogPath: String?
    public let sdkLogPath: String?
    public let enableStats: Bool
    public let playoutDelay: MCForcePlayoutDelay?

    public init(
        subscribeAPI: String = Constants.productionSubscribeURL,
        autoReconnect: Bool = Constants.autoReconnect,
        jitterMinimumDelayMs: UInt = Constants.jitterMinimumDelayMs,
        statsDelayMs: UInt = Constants.statsDelayMs,
        disableAudio: Bool = Constants.disableAudio,
        rtcEventLogPath: String? = nil,
        sdkLogPath: String? = nil,
        enableStats: Bool = Constants.enableStats,
        playoutDelay: MCForcePlayoutDelay? = Constants.playoutDelay
    ) {
        self.subscribeAPI = subscribeAPI
        self.autoReconnect = autoReconnect
        self.jitterMinimumDelayMs = jitterMinimumDelayMs
        self.statsDelayMs = statsDelayMs
        self.disableAudio = disableAudio
        self.rtcEventLogPath = rtcEventLogPath
        self.sdkLogPath = sdkLogPath
        self.enableStats = enableStats
        self.playoutDelay = playoutDelay
    }
}

//
//  SubscriptionConfiguration.swift
//

import Foundation
import MillicastSDK

public struct SubscriptionConfiguration {
    public enum Constants {
        public static let autoReconnect = true
        public static let jitterMinimumDelayMs: UInt = 0
        public static let statsDelayMs: UInt = 1000
        public static let maxBitrate: UInt = 0
        public static let disableAudio = false
        public static let enableStats = true
        public static let playoutDelay: MCForcePlayoutDelay = MCForcePlayoutDelay(min: 0, max: 700)
        public static let forceSmooth: Bool = true
        public static let bweMonitorDurationUs: UInt = 150000
        public static let bweRateChangePercentage: Float = 0.05
        public static let upwardsLayerWaitTimeMs: UInt = 0
        public static let productionSubscribeURL = "https://director.millicast.com/api/director/subscribe"
        public static let developmentSubscribeURL = "https://director-dev.millicast.com/api/director/subscribe"
    }

    public let subscribeAPI: String
    public let autoReconnect: Bool
    public let jitterMinimumDelayMs: UInt
    public let statsDelayMs: UInt
    public let maxBitrate: UInt
    public let disableAudio: Bool
    public let rtcEventLogPath: String?
    public let sdkLogPath: String?
    public let enableStats: Bool
    public let playoutDelay: MCForcePlayoutDelay
    public let forceSmooth: Bool
    public let bweMonitorDurationUs: UInt
    public let bweRateChangePercentage: Float
    public let upwardsLayerWaitTimeMs: UInt

    public init(
        subscribeAPI: String = Constants.productionSubscribeURL,
        autoReconnect: Bool = Constants.autoReconnect,
        jitterMinimumDelayMs: UInt = Constants.jitterMinimumDelayMs,
        statsDelayMs: UInt = Constants.statsDelayMs,
        maxBitrate: UInt = Constants.maxBitrate,
        disableAudio: Bool = Constants.disableAudio,
        rtcEventLogPath: String? = nil,
        sdkLogPath: String? = nil,
        enableStats: Bool = Constants.enableStats,
        playoutDelay: MCForcePlayoutDelay = Constants.playoutDelay,
        forceSmooth: Bool = Constants.forceSmooth,
        bweMonitorDurationUs: UInt = Constants.bweMonitorDurationUs,
        bweRateChangePercentage: Float = Constants.bweRateChangePercentage,
        upwardsLayerWaitTimeMs: UInt = Constants.upwardsLayerWaitTimeMs
    ) {
        self.subscribeAPI = subscribeAPI
        self.autoReconnect = autoReconnect
        self.jitterMinimumDelayMs = jitterMinimumDelayMs
        self.statsDelayMs = statsDelayMs
        self.maxBitrate = maxBitrate
        self.disableAudio = disableAudio
        self.rtcEventLogPath = rtcEventLogPath
        self.sdkLogPath = sdkLogPath
        self.enableStats = enableStats
        self.playoutDelay = playoutDelay
        self.forceSmooth = forceSmooth
        self.bweMonitorDurationUs = bweMonitorDurationUs
        self.bweRateChangePercentage = bweRateChangePercentage
        self.upwardsLayerWaitTimeMs = upwardsLayerWaitTimeMs
    }
}

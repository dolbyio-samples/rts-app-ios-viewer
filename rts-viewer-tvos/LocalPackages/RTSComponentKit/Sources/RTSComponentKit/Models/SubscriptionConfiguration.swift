//
//  SubscriptionConfiguration.swift
//

import Foundation
import MillicastSDK

public struct SubscriptionConfiguration {
    public enum Constants {
        public static let useDevelopmentServer = false
        public static let autoReconnect = true
        public static let jitterMinimumDelayMs: UInt = 20
        public static let statsDelayMs: UInt = 1000
        public static let disableAudio = false
        public static let enableStats = true
        public static let forcePlayoutDelay: MCForcePlayoutDelay? = nil
    }

    public let useDevelopmentServer: Bool
    public let autoReconnect: Bool
    public let jitterMinimumDelayMs: UInt
    public let statsDelayMs: UInt
    public let disableAudio: Bool
    public let rtcEventLogPath: String?
    public let sdkLogPath: String?
    public let enableStats: Bool
    public let forcePlayoutDelay: MCForcePlayoutDelay?

    public init(
        useDevelopmentServer: Bool = Constants.useDevelopmentServer,
        autoReconnect: Bool = Constants.autoReconnect,
        jitterMinimumDelayMs: UInt = Constants.jitterMinimumDelayMs,
        statsDelayMs: UInt = Constants.statsDelayMs,
        disableAudio: Bool = Constants.disableAudio,
        rtcEventLogPath: String? = nil,
        sdkLogPath: String? = nil,
        enableStats: Bool = Constants.enableStats,
        forcePlayoutDelay: MCForcePlayoutDelay? = Constants.forcePlayoutDelay
    ) {
        self.useDevelopmentServer = useDevelopmentServer
        self.autoReconnect = autoReconnect
        self.jitterMinimumDelayMs = jitterMinimumDelayMs
        self.statsDelayMs = statsDelayMs
        self.disableAudio = disableAudio
        self.rtcEventLogPath = rtcEventLogPath
        self.sdkLogPath = sdkLogPath
        self.enableStats = enableStats
        self.forcePlayoutDelay = forcePlayoutDelay
    }
}

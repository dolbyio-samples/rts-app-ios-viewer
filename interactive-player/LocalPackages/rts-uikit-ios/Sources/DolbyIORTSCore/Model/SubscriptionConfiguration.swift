//
//  SubscriptionConfiguration.swift
//

import Foundation

public struct SubscriptionConfiguration {
    public enum Constants {
        public static let useDevelopmentServer = false
        public static let autoReconnect = true
        public static let videoJitterMinimumDelayInMs: UInt = 20
        public static let statsDelayMs: UInt = 1000
        public static let noPlayoutDelay = false
        public static let disableAudio = false
        public static let enableStats = true
    }

    public let useDevelopmentServer: Bool
    public let autoReconnect: Bool
    public let videoJitterMinimumDelayInMs: UInt
    public let statsDelayMs: UInt
    public let noPlayoutDelay: Bool
    public let disableAudio: Bool
    public let rtcEventLogPath: String?
    public let sdkLogPath: String?
    public let enableStats: Bool

    public init(
        useDevelopmentServer: Bool = Constants.useDevelopmentServer,
        autoReconnect: Bool = Constants.autoReconnect,
        videoJitterMinimumDelayInMs: UInt = Constants.videoJitterMinimumDelayInMs,
        statsDelayMs: UInt = Constants.statsDelayMs,
        noPlayoutDelay: Bool = Constants.noPlayoutDelay,
        disableAudio: Bool = Constants.disableAudio,
        rtcEventLogPath: String? = nil,
        sdkLogPath: String? = nil,
        enableStats: Bool = Constants.enableStats
    ) {
        self.useDevelopmentServer = useDevelopmentServer
        self.autoReconnect = autoReconnect
        self.videoJitterMinimumDelayInMs = videoJitterMinimumDelayInMs
        self.statsDelayMs = statsDelayMs
        self.noPlayoutDelay = noPlayoutDelay
        self.disableAudio = disableAudio
        self.rtcEventLogPath = rtcEventLogPath
        self.sdkLogPath = sdkLogPath
        self.enableStats = enableStats
    }
}

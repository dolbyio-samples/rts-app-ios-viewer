//
//  SavedStreamDetail.swift
//

import Foundation
import RTSCore

struct SavedStreamDetail: Identifiable, Equatable {
    let id: UUID
    let accountID: String
    let streamName: String
    let lastUsedDate: Date
    let subscribeAPI: String
    let videoJitterMinimumDelayInMs: UInt
    let minPlayoutDelay: UInt?
    let maxPlayoutDelay: UInt?
    let disableAudio: Bool
    let primaryVideoQuality: VideoQuality
    let maxBitrate: UInt?
    let forceSmooth: Bool
    let monitorDuration: UInt
    let rateChangePercentage: Float
    let upwardsLayerWaitTimeMs: UInt
    let saveLogs: Bool

    init(
        accountID: String,
        streamName: String,
        subscribeAPI: String,
        videoJitterMinimumDelayInMs: UInt,
        minPlayoutDelay: UInt?,
        maxPlayoutDelay: UInt?,
        disableAudio: Bool,
        primaryVideoQuality: VideoQuality,
        maxBitrate: UInt,
        forceSmooth: Bool,
        monitorDuration: UInt,
        rateChangePercentage: Float,
        upwardsLayerWaitTimeMs: UInt,
        saveLogs: Bool,
        dateProvider: DateProvider = DefaultDateProvider()
    ) {
        self.id = UUID()
        self.accountID = accountID
        self.streamName = streamName
        self.lastUsedDate = dateProvider.now
        self.subscribeAPI = subscribeAPI
        self.videoJitterMinimumDelayInMs = videoJitterMinimumDelayInMs
        self.minPlayoutDelay = minPlayoutDelay
        self.maxPlayoutDelay = maxPlayoutDelay
        self.disableAudio = disableAudio
        self.primaryVideoQuality = primaryVideoQuality
        self.maxBitrate = maxBitrate
        self.forceSmooth = forceSmooth
        self.monitorDuration = monitorDuration
        self.rateChangePercentage = rateChangePercentage
        self.upwardsLayerWaitTimeMs = upwardsLayerWaitTimeMs
        self.saveLogs = saveLogs
    }
}

extension SavedStreamDetail {
    init?(managedObject: StreamDetailManagedObject) {
        guard
            let accountID = managedObject.accountID,
            let streamName = managedObject.streamName,
            let lastUsedDate = managedObject.lastUsedDate,
            let storedVideoQuality = managedObject.primaryVideoQuality,
            let subscribeAPI = managedObject.subscribeAPI,
            let primaryVideoQuality = VideoQuality(rawValue: storedVideoQuality)
        else {
            return nil
        }
        let minPlayoutDelay = managedObject.minPlayoutDelay
        let maxPlayoutDelay = managedObject.maxPlayoutDelay
        let disableAudio = managedObject.disableAudio
        let saveLogs = managedObject.saveLogs
        let maxBitrate = managedObject.maxBitrate ?? 0
        let forceSmooth = managedObject.forceSmooth
        let duration = managedObject.bweMonitorDurationUs ?? NSNumber(value: SubscriptionConfiguration.Constants.bweMonitorDurationUs)
        let rateChange = managedObject.bweRateChangePercentage ?? NSNumber(value: SubscriptionConfiguration.Constants.bweRateChangePercentage)
        let waitTime = managedObject.upwardsLayerWaitTimeMs ?? NSNumber(value: SubscriptionConfiguration.Constants.upwardsLayerWaitTimeMs)

        self.id = UUID()
        self.accountID = accountID
        self.streamName = streamName
        self.lastUsedDate = lastUsedDate
        self.subscribeAPI = subscribeAPI
        self.videoJitterMinimumDelayInMs = UInt(managedObject.videoJitterMinimumDelayInMs)
        self.minPlayoutDelay = minPlayoutDelay.map { UInt(truncating: $0) }
        self.maxPlayoutDelay = maxPlayoutDelay.map { UInt(truncating: $0) }
        self.disableAudio = disableAudio
        self.forceSmooth = forceSmooth
        self.primaryVideoQuality = primaryVideoQuality
        self.maxBitrate = UInt(truncating: maxBitrate)
        self.monitorDuration = UInt(truncating: duration)
        self.rateChangePercentage = Float(truncating: rateChange)
        self.upwardsLayerWaitTimeMs = UInt(truncating: waitTime)
        self.saveLogs = saveLogs
    }
}

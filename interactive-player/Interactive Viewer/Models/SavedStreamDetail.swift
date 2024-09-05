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
    let minPlayoutDelay: UInt
    let maxPlayoutDelay: UInt
    let disableAudio: Bool
    let primaryVideoQuality: VideoQuality
    let maxBitrate: UInt
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
        minPlayoutDelay: UInt,
        maxPlayoutDelay: UInt,
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

        let disableAudio = managedObject.disableAudio
        let saveLogs = managedObject.saveLogs

        self.id = UUID()
        self.accountID = accountID
        self.streamName = streamName
        self.lastUsedDate = lastUsedDate
        self.subscribeAPI = subscribeAPI
        self.videoJitterMinimumDelayInMs = UInt(managedObject.videoJitterMinimumDelayInMs)
        self.minPlayoutDelay = UInt(managedObject.minPlayoutDelay)
        self.maxPlayoutDelay = UInt(managedObject.maxPlayoutDelay)
        self.disableAudio = disableAudio
        self.forceSmooth = managedObject.forceSmooth
        self.primaryVideoQuality = primaryVideoQuality
        self.maxBitrate = UInt(managedObject.maxBitrate)
        self.monitorDuration = UInt(managedObject.bweMonitorDurationUs)
        self.rateChangePercentage = Float(managedObject.bweRateChangePercentage)
        self.upwardsLayerWaitTimeMs = UInt(managedObject.upwardsLayerWaitTimeMs)
        self.saveLogs = saveLogs
    }
}

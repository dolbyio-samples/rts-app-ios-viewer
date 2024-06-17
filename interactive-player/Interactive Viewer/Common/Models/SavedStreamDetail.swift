//
//  SavedStreamDetail.swift
//

import DolbyIORTSUIKit
import Foundation

struct SavedStreamDetail: Identifiable, Equatable {
    let id: UUID
    let accountID: String
    let streamName: String
    let lastUsedDate: Date
    let useDevelopmentServer: Bool
    let videoJitterMinimumDelayInMs: UInt
    let minPlayoutDelay: UInt?
    let maxPlayoutDelay: UInt?
    let disableAudio: Bool
    let primaryVideoQuality: VideoQuality
    let saveLogs: Bool

    init(
        accountID: String,
        streamName: String,
        useDevelopmentServer: Bool,
        videoJitterMinimumDelayInMs: UInt,
        minPlayoutDelay: UInt?,
        maxPlayoutDelay: UInt?,
        disableAudio: Bool,
        primaryVideoQuality: VideoQuality,
        saveLogs: Bool,
        dateProvider: DateProvider = DefaultDateProvider()
    ) {
        self.id = UUID()
        self.accountID = accountID
        self.streamName = streamName
        self.lastUsedDate = dateProvider.now
        self.useDevelopmentServer = useDevelopmentServer
        self.videoJitterMinimumDelayInMs = videoJitterMinimumDelayInMs
        self.minPlayoutDelay = minPlayoutDelay
        self.maxPlayoutDelay = maxPlayoutDelay
        self.disableAudio = disableAudio
        self.primaryVideoQuality = primaryVideoQuality
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
            let primaryVideoQuality = VideoQuality(rawValue: storedVideoQuality)
        else {
            return nil
        }
        let useDevelopmentServer = managedObject.useDevelopmentServer
        let minPlayoutDelay = managedObject.minPlayoutDelay
        let maxPlayoutDelay = managedObject.maxPlayoutDelay
        let disableAudio = managedObject.disableAudio
        let saveLogs = managedObject.saveLogs

        self.id = UUID()
        self.accountID = accountID
        self.streamName = streamName
        self.lastUsedDate = lastUsedDate
        self.useDevelopmentServer = useDevelopmentServer
        self.videoJitterMinimumDelayInMs = UInt(managedObject.videoJitterMinimumDelayInMs)
        self.minPlayoutDelay = minPlayoutDelay.map { UInt(truncating: $0) }
        self.maxPlayoutDelay = maxPlayoutDelay.map { UInt(truncating: $0) }
        self.disableAudio = disableAudio
        self.primaryVideoQuality = primaryVideoQuality
        self.saveLogs = saveLogs
    }
 }

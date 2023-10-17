//
//  SavedStreamDetail.swift
//

import DolbyIORTSCore
import Foundation

struct SavedStreamDetail: Identifiable, Equatable {
    let id: UUID
    let accountID: String
    let streamName: String
    let lastUsedDate: Date
    let useDevelopmentServer: Bool
    let videoJitterMinimumDelayInMs: UInt
    let noPlayoutDelay: Bool
    let disableAudio: Bool
    let primaryVideoQuality: VideoQuality

    init(
        accountID: String,
        streamName: String,
        useDevelopmentServer: Bool,
        videoJitterMinimumDelayInMs: UInt,
        noPlayoutDelay: Bool,
        disableAudio: Bool,
        primaryVideoQuality: VideoQuality,
        dateProvider: DateProvider = DefaultDateProvider()
    ) {
        self.id = UUID()
        self.accountID = accountID
        self.streamName = streamName
        self.lastUsedDate = dateProvider.now
        self.useDevelopmentServer = useDevelopmentServer
        self.videoJitterMinimumDelayInMs = videoJitterMinimumDelayInMs
        self.noPlayoutDelay = noPlayoutDelay
        self.disableAudio = disableAudio
        self.primaryVideoQuality = primaryVideoQuality
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
        let noPlayoutDelay = managedObject.noPlayoutDelay
        let disableAudio = managedObject.disableAudio

        self.id = UUID()
        self.accountID = accountID
        self.streamName = streamName
        self.lastUsedDate = lastUsedDate
        self.useDevelopmentServer = useDevelopmentServer
        self.videoJitterMinimumDelayInMs = UInt(managedObject.videoJitterMinimumDelayInMs)
        self.noPlayoutDelay = noPlayoutDelay
        self.disableAudio = disableAudio
        self.primaryVideoQuality = primaryVideoQuality
    }
 }

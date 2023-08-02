//
//  StreamDetail.swift
//

import Foundation

struct StreamDetail: Identifiable, Equatable {
    let id: UUID
    let accountID: String
    let streamName: String
    let isDev: Bool
    let forcePlayoutDelay: Bool
    let disableAudio: Bool
    let saveLogs: Bool
    let jitterBufferDelay: Int
    let lastUsedDate: Date
}

 extension StreamDetail {
    init?(managedObject: StreamDetailManagedObject) {
        guard
            let accountID = managedObject.accountID,
            let streamName = managedObject.streamName,
            let lastUsedDate = managedObject.lastUsedDate
        else {
            return nil
        }
        let isDev = managedObject.isDev
        let forcePlayoutDelay = managedObject.forcePlayoutDelay
        let disableAudio = managedObject.disableAudio
        let saveLogs = managedObject.saveLogs
        let jitterBufferDelay = managedObject.jitterBufferDelay

        self.id = UUID()
        self.accountID = accountID
        self.streamName = streamName
        self.lastUsedDate = lastUsedDate
        self.isDev = isDev
        self.forcePlayoutDelay = forcePlayoutDelay
        self.saveLogs = saveLogs
        self.jitterBufferDelay = Int(jitterBufferDelay)
        self.disableAudio = disableAudio
    }
 }

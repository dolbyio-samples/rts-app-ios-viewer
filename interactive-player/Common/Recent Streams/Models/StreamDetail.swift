//
//  StreamDetail.swift
//

import Foundation

struct StreamDetail: Identifiable, Equatable {
    let id: UUID
    let accountID: String
    let streamName: String
    let isDev: String
    let forcePlayoutDelay: String
    let disableAudio: String
    let lastUsedDate: Date
}

// swiftlint:disable force_cast
 extension StreamDetail {
    init?(managedObject: StreamDetailManagedObject) {
        guard
            let accountID = managedObject.accountID,
            let streamName = managedObject.streamName,
            let isDev = managedObject.isDev,
            let forcePlayoutDelay = managedObject.forcePlayoutDelay,
            let disableAudio = managedObject.disableAudio,
            let lastUsedDate = managedObject.lastUsedDate
        else {
            return nil
        }
        self.id = UUID()
        self.accountID = accountID
        self.streamName = streamName
        self.lastUsedDate = lastUsedDate
        self.isDev = isDev
        self.forcePlayoutDelay = forcePlayoutDelay
        self.disableAudio = disableAudio
    }
     // swiftlint:enable force_cast
 }

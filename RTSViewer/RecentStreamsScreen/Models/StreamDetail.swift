//
//  StreamDetail.swift
//

import Foundation

struct StreamDetail: Identifiable {
    let id: UUID
    let accountID: String
    let streamName: String
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
        self.id = UUID()
        self.accountID = accountID
        self.streamName = streamName
        self.lastUsedDate = lastUsedDate
    }
 }

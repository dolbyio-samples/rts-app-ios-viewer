//
//  StreamDetail.swift
//

import Foundation

struct StreamDetail: Equatable, Identifiable {
    let id = UUID()
    let streamName: String
    let accountID: String

    init(streamName: String, accountID: String) {
        self.streamName = streamName
        self.accountID = accountID
    }
}

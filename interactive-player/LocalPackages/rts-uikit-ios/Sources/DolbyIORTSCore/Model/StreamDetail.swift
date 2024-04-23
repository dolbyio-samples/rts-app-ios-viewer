//
//  StreamDetail.swift
//

import Foundation

public struct StreamDetail: Equatable, Identifiable {
    public let id = UUID()
    public let streamName: String
    public let accountID: String

    public init(streamName: String, accountID: String) {
        self.streamName = streamName
        self.accountID = accountID
    }
}

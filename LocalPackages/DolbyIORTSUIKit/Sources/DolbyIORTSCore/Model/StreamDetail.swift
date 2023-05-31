//
//  StreamDetail.swift
//

import Foundation

public struct StreamDetail: Equatable {
    public let streamName: String
    public let accountID: String
    public var streamId: String { "\(self.accountID)/\(self.streamName)" }
}

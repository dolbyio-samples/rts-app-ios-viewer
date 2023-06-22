//
//  RecentStreamButtonViewModel.swift
//

import Foundation

struct RecentStreamButtonViewModel {
    private let streamName: String
    private let accountID: String

    init(streamName: String, accountID: String) {
        self.streamName = streamName
        self.accountID = accountID
    }

    var buttonText: String {
        "\(streamName) / \(accountID)"
    }
}

//
//  ChannelGridViewModel.swift
//

import Foundation
import MillicastSDK
import os
import SwiftUI

@MainActor
final class ChannelGridViewModel: ObservableObject {
    static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: ChannelGridViewModel.self)
    )

    let channels: [SourcedChannel]

    init(channels: [SourcedChannel]) {
        self.channels = channels
    }
}

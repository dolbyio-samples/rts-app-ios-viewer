//
//  ChannelGridViewModel.swift
//  Interactive Player
//

import Foundation
import MillicastSDK
import os
import RTSCore
import SwiftUI

final class ChannelGridViewModel: ObservableObject {
    static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: GridViewModel.self)
    )
    let channels: [SourcedChannel]

    init(channels: [SourcedChannel]) {
        self.channels = channels
    }
}

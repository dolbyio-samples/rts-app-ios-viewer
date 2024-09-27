//
//  ChannelGridViewModel.swift
//

import Combine
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

    @Published var currentlyFocusedChannel: SourcedChannel?
    @Published private(set) var channels: [SourcedChannel]
    private var cancellables: [AnyCancellable] = []

    init(channels: [SourcedChannel]) {
        self.channels = channels
    }
}

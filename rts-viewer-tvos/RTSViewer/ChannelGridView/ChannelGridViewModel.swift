//
//  ChannelGridViewModel.swift
//

import Foundation
import SwiftUI

@MainActor
final class ChannelGridViewModel: ObservableObject {
    let channels: [SourcedChannel]

    init(channels: [SourcedChannel]) {
        self.channels = channels
    }
}

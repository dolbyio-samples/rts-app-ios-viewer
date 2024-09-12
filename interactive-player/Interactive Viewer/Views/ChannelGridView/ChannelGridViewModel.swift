//
//  ChannelGridViewModel.swift
//

import Foundation
import MillicastSDK
import os
import RTSCore
import SwiftUI

final class ChannelGridViewModel: ObservableObject {
    let channels: [SourcedChannel]

    init(channels: [SourcedChannel]) {
        self.channels = channels
    }
}

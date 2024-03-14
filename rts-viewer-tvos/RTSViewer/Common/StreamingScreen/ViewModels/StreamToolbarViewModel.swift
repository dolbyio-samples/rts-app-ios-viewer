//
//  StreamToolbarViewModel.swift
//

import Combine
import Foundation
import RTSComponentKit
import UIKit

final class StreamToolbarViewModel: ObservableObject {
    let isStreamActive: Bool
    let isLiveIndicatorEnabled: Bool
    let dataStore: RTSDataStore

    init(
        isStreamActive: Bool,
        isLiveIndicatorEnabled: Bool,
        dataStore: RTSDataStore
    ) {
        self.isStreamActive = isStreamActive
        self.isLiveIndicatorEnabled = isLiveIndicatorEnabled
        self.dataStore = dataStore
    }
}

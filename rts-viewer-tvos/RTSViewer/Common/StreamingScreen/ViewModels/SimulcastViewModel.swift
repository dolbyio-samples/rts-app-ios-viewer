//
//  StatisticsViewModel.swift
//

import Combine
import Foundation
import OSLog
import RTSComponentKit
import UIKit

final class SimulcastViewModel: ObservableObject {

    private let dataStore: RTSDataStore

    init(dataStore: RTSDataStore) {
        self.dataStore = dataStore
    }

    func setLayer(quality: VideoQuality) async {
        do {
            try await dataStore.selectLayer(videoQuality: quality)
        } catch {
            // No-op
        }
    }
}

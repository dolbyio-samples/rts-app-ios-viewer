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
    private static let logger = Logger.make(category: String(describing: SimulcastViewModel.self))

    init(dataStore: RTSDataStore) {
        self.dataStore = dataStore
    }

    func setLayer(streamType: StreamType) async {
        do {
            try await dataStore.selectLayer(streamType: streamType)
        } catch {
            Self.logger.error("💼 setLayer failed - \(error.localizedDescription)")
        }
    }
}

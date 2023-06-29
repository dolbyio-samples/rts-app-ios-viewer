//
//  StatisticsViewModel.swift
//

import Combine
import Foundation
import RTSComponentKit
import UIKit

final class SimulcastViewModel: ObservableObject {

    private let dataStore: RTSDataStore

    init(dataStore: RTSDataStore) {
        self.dataStore = dataStore
    }

    func setLayer(streamType: StreamType) {
        dataStore.selectLayer(streamType: streamType)
    }
}

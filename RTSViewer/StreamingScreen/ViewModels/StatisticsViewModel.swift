//
//  StatisticsViewModel.swift
//

import Combine
import Foundation
import RTSComponentKit
import UIKit

final class StatisticsViewModel: ObservableObject {

    @Published private(set) var statisticsData: StatisticsData?

    private let dataStore: RTSDataStore
    private var subscriptions: [AnyCancellable] = []

    init(dataStore: RTSDataStore) {
        self.dataStore = dataStore
        self.statisticsData = dataStore.statisticsData

        dataStore.$statisticsData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] stats in
                self?.statisticsData = stats
            }
            .store(in: &subscriptions)
    }
}

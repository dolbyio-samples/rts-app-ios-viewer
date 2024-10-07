//
//  ChannelVideoViewModel.swift
//

import Combine
import Foundation
import os
import RTSCore
import SwiftUI

@MainActor
class ChannelVideoViewModel: ObservableObject {
    @Published var showStatsView: Bool
    @Published var isFocused: Bool
    @Published var statistics: StreamStatistics?
    @Published var videoQualityList: [VideoQuality]

    let channel: Channel
    private var cancellables = [AnyCancellable]()

    init(channel: Channel) {
        self.channel = channel

        self.showStatsView = channel.showStatsView
        self.isFocused = channel.isFocusedChannel
        self.statistics = channel.streamStatistics
        self.videoQualityList = channel.videoQualityList

        setListeners()
    }
}

private extension ChannelVideoViewModel {
    func setListeners() {
        channel.$showStatsView
            .receive(on: DispatchQueue.main)
            .sink { [weak self] show in
            self?.showStatsView = show
        }
        .store(in: &cancellables)

        channel.$isFocusedChannel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isFocused in
            self?.isFocused = isFocused
        }
        .store(in: &cancellables)

        channel.$streamStatistics
            .receive(on: DispatchQueue.main)
            .sink { [weak self] stats in
            self?.statistics = stats
        }
        .store(in: &cancellables)

        channel.$videoQualityList
            .receive(on: DispatchQueue.main)
            .sink { [weak self] list in
            self?.videoQualityList = list
        }
        .store(in: &cancellables)
    }
}

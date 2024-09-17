//
//  SettingsMultichannelViewModel.swift
//

import Foundation
import MillicastSDK
import RTSCore

final class SettingsMultichannelViewModel: ObservableObject {
    @Published var channel: Channel

    init(channel: Channel) {
        self.channel = channel
    }

    func updateSelectedVideoQuality(with quality: VideoQuality) {
        channel.enableVideo(with: quality)
    }

    func shouldShowStatsView(showStats: Bool) {
        channel.shouldShowStatsView(showStats: showStats)
    }
}

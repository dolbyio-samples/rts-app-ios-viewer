//
//  SettingsMultichannelViewModel.swift
//

import Foundation
import MillicastSDK
import RTSCore

final class SettingsMultichannelViewModel {
    var videoQualityList: [VideoQuality] = []
    var selectedVideoQuality: VideoQuality
    let channel: SourcedChannel

    init(channel: SourcedChannel, videoQualityList: [VideoQuality], selectedVideoQuality: VideoQuality) {
        self.channel = channel
        self.videoQualityList = videoQualityList
        self.selectedVideoQuality = selectedVideoQuality
    }
}

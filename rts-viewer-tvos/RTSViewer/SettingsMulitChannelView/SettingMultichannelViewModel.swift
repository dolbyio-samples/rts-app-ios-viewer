//
//  SettingsMultichannelViewModel.swift
//

import Foundation
import MillicastSDK
import RTSCore

final class SettingMultichannelViewModel {
    let channel: SourcedChannel?
//    let videoQualityList: [VideoQuality]
//    let selectedVideoQuality: VideoQuality

    init(channel: SourcedChannel?) {
//    init(channel: SourcedChannel, videoQualityList: [VideoQuality], selectedVideoQuality: VideoQuality) {
        self.channel = channel
//        self.videoQualityList = videoQualityList
//        self.selectedVideoQuality = selectedVideoQuality
    }
}

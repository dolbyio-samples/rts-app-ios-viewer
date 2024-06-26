//
//  SettingsViewModel.swift
//

import Foundation
import MillicastSDK
import RTSCore

final class SettingViewModel {
    let source: StreamSource
    let videoQualityList: [VideoQuality]
    let selectedVideoQuality: VideoQuality

    init(source: StreamSource, videoQualityList: [VideoQuality], selectedVideoQuality: VideoQuality) {
        self.source = source
        self.videoQualityList = videoQualityList
        self.selectedVideoQuality = selectedVideoQuality
    }
}

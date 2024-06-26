//
//  StatisticsViewModel.swift
//

import Foundation
import OSLog
import MillicastSDK
import RTSCore
import UIKit

struct SimulcastViewModel {
    let source: StreamSource
    let videoQualityList: [VideoQuality]
    let selectedVideoQuality: VideoQuality
}

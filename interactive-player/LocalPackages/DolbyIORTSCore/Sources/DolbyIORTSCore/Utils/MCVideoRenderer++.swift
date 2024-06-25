//
//  MCVideoRenderer++.swift
//

import Foundation
import MillicastSDK

extension MCVideoRenderer {
    public var videoSize: CGSize {
        switch self {
        case let sampleBufferRenderer as MCCMSampleBufferVideoRenderer:
            sampleBufferRenderer.videoSize
        case let acceleratedVideoRenderer as MCAcceleratedVideoRenderer:
            acceleratedVideoRenderer.videoSize
        default:
            fatalError("Unknown renderer type")
        }
    }
}

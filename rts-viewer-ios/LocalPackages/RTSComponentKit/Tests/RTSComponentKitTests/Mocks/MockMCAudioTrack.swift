//
//  MockMCAudioTrack.swift
//

import MillicastSDK

final class MockMCAudioTrack: MCAudioTrack {

    private(set) var addedAudioRenderer: MCAudioRenderer?
    override func add(_ renderer: MCAudioRenderer!) {
        addedAudioRenderer = renderer
    }
}

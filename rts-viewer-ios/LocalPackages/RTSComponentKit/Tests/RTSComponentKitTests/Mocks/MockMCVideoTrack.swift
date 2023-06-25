//
//  MockMCVideoTrack.swift
//

import MillicastSDK

final class MockMCVideoTrack: MCVideoTrack {

    private(set) var addedVideoRenderer: MCVideoRenderer?
    override func add(_ renderer: MCVideoRenderer!) {
        addedVideoRenderer = renderer
    }
}

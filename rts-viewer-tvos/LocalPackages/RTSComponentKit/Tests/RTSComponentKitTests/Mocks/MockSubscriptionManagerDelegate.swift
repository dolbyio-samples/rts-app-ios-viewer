//
//  MockSubscriptionManagerDelegate.swift
//

@testable import RTSComponentKit

import Foundation
import MillicastSDK

final class MockSubscriptionManagerDelegate: SubscriptionManagerDelegate {
    
    enum Event {
        case onSubscribed
        case onSubscribedError(reason: String)
        case onVideoTrack(track: MCVideoTrack, mid: String)
        case onAudioTrack(track: MCAudioTrack, mid: String)
        case onStatsReport(report: MCStatsReport)
        case onConnected
        case onStreamActive
        case onStreamInactive
        case onStreamStopped
        case onConnectionError(reason: String)
        case onStreamLayers(mid: String?, activeLayers: [MCLayerData]?, inactiveLayers: [String]?)
    }

    private(set) var events: [Event] = []

    func onSubscribed() {
        events.append(.onSubscribed)
    }

    func onSubscribedError(_ reason: String) {
        events.append(.onSubscribed)
    }

    func onVideoTrack(_ track: MCVideoTrack, withMid mid: String) {
        events.append(.onVideoTrack(track: track, mid: mid))
    }

    func onAudioTrack(_ track: MCAudioTrack, withMid mid: String) {
        events.append(.onAudioTrack(track: track, mid: mid))
    }

    func onStatsReport(report: MCStatsReport) {
        events.append(.onStatsReport(report: report))
    }

    func onConnected() {
        events.append(.onConnected)
    }

    func onStreamActive() {
        events.append(.onStreamActive)
    }

    func onStreamInactive() {
        events.append(.onStreamInactive)
    }

    func onStreamStopped() {
        events.append(.onStreamStopped)
    }

    func onConnectionError(reason: String) {
        events.append(.onConnectionError(reason: reason))
    }

    func onStreamLayers(_ mid: String?, activeLayers: [MCLayerData]?, inactiveLayers: [String]?) {
        events.append(.onStreamLayers(mid: mid, activeLayers: activeLayers, inactiveLayers: inactiveLayers))
    }
}

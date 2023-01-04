//
//  File.swift
//  
//
//  Created by Raveendran, Aravind on 7/1/2023.
//

import Foundation
import MillicastSDK

class SubscriptionListener: MCSubscriberListener {
    func onSubscribed() {
        // TODO:
    }
    
    func onSubscribedError(_ reason: String!) {
        // TODO:
    }
    
    func onVideoTrack(_ track: MCVideoTrack!, withMid mid: String!) {
        // TODO:
    }
    
    func onAudioTrack(_ track: MCAudioTrack!, withMid mid: String!) {
        // TODO:
    }
    
    func onActive(_ streamId: String!, tracks: [String]!, sourceId: String!) {
        // TODO:
    }
    
    func onInactive(_ streamId: String!, sourceId: String!) {
        // TODO:
    }
    
    func onStopped() {
        // TODO:
    }
    
    func onVad(_ mid: String!, sourceId: String!) {
        // TODO:
    }
    
    func onLayers(_ mid: String!, activeLayers: [MCLayerData]!, inactiveLayers: [MCLayerData]!) {
        // TODO:
    }
    
    func onConnected() {
        // TODO:
    }
    
    func onConnectionError(_ status: Int32, withReason reason: String!) {
        // TODO:
    }
    
    func onSignalingError(_ message: String!) {
        // TODO:
    }
    
    func onStatsReport(_ report: MCStatsReport!) {
        // TODO:
    }
    
    func onViewerCount(_ count: Int32) {
        // TODO:
    }
}

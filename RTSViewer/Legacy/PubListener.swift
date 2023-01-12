//
//  PubListener.swift
//  Millicast SDK Sample App in Swift
//

import Foundation
import MillicastSDK

/**
 * Implementation of Publisher's Listener.
 * This handles events sent to the Publisher being listened to.
 */
class PubListener: MCPublisherListener {
    var mcMan: MillicastManager
    
    init() {
        let logTag = "[Pub][Ltn] "
        mcMan = MillicastManager.getInstance()
        print(logTag + "PubListener created.")
    }
    
    func onPublishing() {
        let logTag = "[Pub][Ltn][On] "
        mcMan.setPubState(to: .publishing)
        print(logTag + "Publishing to Millicast.")
    }
    
    func onPublishingError(_ error: String!) {
        let logTag = "[Pub][Ltn][Error] "
        print(logTag + "\(error).")
    }

    func onConnected() {
        mcMan.setPubState(to: .connected)
        let logTag = "[Pub][Ltn][Con] "
        print(logTag + "Connected to Millicast.")
        mcMan.startPub()
        print(logTag + "Trying to publish to Millicast.")
    }
    
    func onConnectionError(_ status: Int32, withReason reason: String!) {
        let logTag = "[Pub][Ltn][Con][Error] "
        mcMan.setPubState(to: .disconnected)
        mcMan.showAlert(logTag + "Failed to connect as \(reason!)! Status: \(status)")
    }
    
    func onSignalingError(_ error: String!) {
        let logTag = "[Pub][Ltn][Error][Sig] "
        print(logTag + "\(error).")
    }
    
    func onStatsReport(_ report: MCStatsReport!) {
        let logTag = "[Pub][Ltn][Stat] "
        let type = MCOutboundRtpStreamStats.get_type()
        mcMan.printStats(forType: type, report: report, logTag: logTag)
    }
    
    func onViewerCount(_ count: Int32) {
        let logTag = "[Pub][Ltn][Viewer] "
        print(logTag + "Count: \(count).")
    }
    
    func onActive() {
        let logTag = "[Pub][Ltn][Viewer][Active] "
        print(logTag + "A viewer has subscribed to our stream.")
    }
    
    func onInactive() {
        let logTag = "[Pub][Ltn][Viewer][Active][In] "
        print(logTag + "No viewers are currently subscribed to our stream.")
    }
}

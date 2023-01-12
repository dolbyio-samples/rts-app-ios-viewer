//
//  SubscriptionListener.swift
//

import Combine
import Foundation
import MillicastSDK

protocol SubscriptionListenerDelegate: AnyObject {
    func onSubscribed()
    func onSubscribedError(_ reason: String)
    func onVideoTrack(_ track: MCVideoTrack, withMid mid: String)
    func onAudioTrack(_ track: MCAudioTrack, withMid mid: String)
    func onConnected()
    func onStreamActive()
    func onStreamInactive()
    func onStreamStopped()
    func onConnectionError(reason: String)
}

final class SubscriptionListener: MCSubscriberListener {

    weak var delegate: SubscriptionListenerDelegate?

    func onSubscribed() {
        delegate?.onSubscribed()
    }

    func onSubscribedError(_ reason: String!) {
        delegate?.onSubscribedError(reason)
    }

    func onVideoTrack(_ track: MCVideoTrack!, withMid mid: String!) {
        delegate?.onVideoTrack(track, withMid: mid)
    }

    func onAudioTrack(_ track: MCAudioTrack!, withMid mid: String!) {
        delegate?.onAudioTrack(track, withMid: mid)
    }

    func onActive(_ streamId: String!, tracks: [String]!, sourceId: String!) {
        delegate?.onStreamActive()
    }

    func onInactive(_ streamId: String!, sourceId: String!) {
        delegate?.onStreamInactive()
    }

    func onStopped() {
        delegate?.onStreamStopped()
    }

    func onVad(_ mid: String!, sourceId: String!) {
        // TODO:
    }

    func onLayers(_ mid: String!, activeLayers: [MCLayerData]!, inactiveLayers: [MCLayerData]!) {
        // TODO:
    }

    func onConnected() {
        delegate?.onConnected()
    }

    func onConnectionError(_ status: Int32, withReason reason: String!) {
        delegate?.onConnectionError(reason: reason)
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

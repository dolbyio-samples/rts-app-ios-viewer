//
//  PlayoutDelay.swift
//
import MillicastSDK
import RTSCore

struct PlayoutDelay {
    let min: Int32
    let max: Int32

    init(min: Int32, max: Int32) {
        assert(min <= max)
        self.min = min
        self.max = max
    }

    init() {
        let native = SubscriptionConfiguration.Constants.playoutDelay
        self.min = native.minimum
        self.max = native.maximum
    }
}

extension MCForcePlayoutDelay {
    convenience init(_ playoutDelay: PlayoutDelay) {
        self.init()
        self.minimum = playoutDelay.min
        self.maximum = playoutDelay.max
    }
}

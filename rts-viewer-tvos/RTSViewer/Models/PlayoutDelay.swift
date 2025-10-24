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
        self.min = 0
        self.max = 0
    }
}

extension MCForcePlayoutDelay {
    convenience init(_ playoutDelay: PlayoutDelay) {
        self.init()
        self.minimum = playoutDelay.min
        self.maximum = playoutDelay.max
    }
}

//
//  MockNetworkMonitor.swift
//

import Network
import RTSComponentKit
import XCTest

final class MockNetworkMonitor: NetworkMonitor {
    enum Event {
        case startMonitoring
        case stopMonitoring
    }
    private(set) var events: [Event] = []

    override init() {
        // No-op
    }

    var networkStatusToReturn: Bool?
    override func startMonitoring(onUpdate: ((Bool) -> Void)?) {
        guard let status = networkStatusToReturn else {
            fatalError("Variable not set 'networkPathToReturn'")
        }

        events.append(.startMonitoring)
        onUpdate?(status)
    }

    override func stopMonitoring() {
        events.append(.startMonitoring)
    }
}

//
//  NetworkMonitor.swift
//

import Foundation
import Network

open class NetworkMonitor {

    private let monitor = NWPathMonitor()

    static let shared = NetworkMonitor()

    var isReachable: Bool { status == .satisfied }
    private(set) var isReachableOnCellular: Bool = true
    private(set) var status: NWPath.Status = .requiresConnection

    public init() {}

    open func startMonitoring(onUpdate: ((Bool) -> Void)?) {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.status = path.status
            self?.isReachableOnCellular = path.isExpensive
            onUpdate?(path.status == .satisfied)
        }

        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }

    open func stopMonitoring() {
        monitor.cancel()
    }
}

//
//  NetworkMonitor.swift
//

import Foundation
import Network

public class NetworkMonitor {
    public static let shared = NetworkMonitor()

    public var isReachable: Bool { status == .satisfied }
    public var isReachableOnCellular: Bool = true

    var status: NWPath.Status = .requiresConnection
    let monitor = NWPathMonitor()

    public func startMonitoring(onUpdate: ((NWPath) -> Void)?) {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.status = path.status
            self?.isReachableOnCellular = path.isExpensive
            onUpdate?(path)
        }

        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }

    public func stopMonitoring() {
        monitor.cancel()
    }
}

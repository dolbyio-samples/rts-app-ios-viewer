//
//  NetworkMonitor.swift
//

import Foundation
import Network

public protocol NetworkMonitorUpdateHandler {
    func onConnected(path: NWPath)
    func onDisconnected(path: NWPath)
}

public class NetworkMonitor {
    public static let shared = NetworkMonitor()

    public var isReachable: Bool { status == .satisfied }
    public var isReachableOnCellular: Bool = true
    public var updateHandler: NetworkMonitorUpdateHandler?

    var status: NWPath.Status = .requiresConnection
    let monitor = NWPathMonitor()

    public func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.status = path.status
            self?.isReachableOnCellular = path.isExpensive

            if path.status == .satisfied {
                self?.updateHandler?.onConnected(path: path)
            } else {
                self?.updateHandler?.onDisconnected(path: path)
            }
        }

        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }

    public func stopMonitoring() {
        monitor.cancel()
    }
}

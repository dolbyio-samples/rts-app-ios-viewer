//
//  SDKLogger.swift
//
    
import MillicastSDK
import os
import Combine
import Collections
import Foundation

public struct Diagnostics: Codable, Equatable {
    init(logs: [String], stats: [String]) {
        self.logs = logs
        self.stats = stats
        let processInfo = ProcessInfo.processInfo
        self.osInformation = processInfo.operatingSystemVersionString
        self.sdkVer = MCLogger.getVersion()
        self.webrtcVer = MCLogger.getWebrtcVersion()
    }
   
    let sdkVer: String
    let webrtcVer: String
    let osInformation: String
    let logs: [String]
    let stats: [String]
}

public struct TelemetryReport: Codable {
    let from: String = "Native iOS/tvOS SDK Test App"
    let name: String = "Native iOS/tvOS SDK Test App"
    let description: String = "Native iOS/tvOS SDK report"
    let url: String = Bundle.main.bundleIdentifier!
    let email: String = "Dan.Coffey@dolby.com"
    let diagnostics: Diagnostics
}

public class SDKLogger: NSObject, MCLoggerDelegate {
    private let filterLogLevel: MCLogLevel
    private let streamTag: String?
    private let telemetryUrl: URL
    private let dispatchQueue: DispatchQueue = DispatchQueue(label: "rtscore.SDKLogger", qos: .background)
    private static let LOG_SIZE = 1000
    private var logs: Deque<String> = []
    private var stats: Deque<String> = []
    private var timer: DispatchSourceTimer?
    let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: SDKLogger.self)
    )
    
    var formattedDateNow: String {
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS" // SSS for milliseconds
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: now)
    }
    
    public init(loglevel: MCLogLevel = .warning, streamTag: String? = nil, telemetryUrl: URL) {
        self.filterLogLevel = loglevel
        self.streamTag = streamTag
        self.telemetryUrl = telemetryUrl
        
        self.logs.reserveCapacity(SDKLogger.LOG_SIZE)
        self.stats.reserveCapacity(SDKLogger.LOG_SIZE)
        super.init()
        let timer = DispatchSource.makeTimerSource(queue: dispatchQueue)
        timer.setEventHandler {
            [weak self] in
            self?.sendToTelemetry()
        }
        timer.schedule(deadline: .now().advanced(by: .seconds(10)), repeating: .seconds(3600))
        timer.activate()
        self.timer = timer
        MCLogger.setLogLevelWithSdk(.debug, webrtc: .debug, websocket: .warning)
        MCLogger.setDelegate(self)
        
    }
    
    public func onStats(_ report: MCSubscriberStats) {
        dispatchQueue.async { [weak self] in
            guard let self else { return }
            self.stats.insert(report.toJSON(.full), at: 0)
            if self.stats.count > SDKLogger.LOG_SIZE {
                self.stats.removeLast()
            }
        }
    }
    
    public func onLog(withMessage message: String, level: MCLogLevel) {
        dispatchQueue.async { [weak self] in
            guard let self, level.rawValue <= filterLogLevel.rawValue else { return }
            
            let tag = if let streamTag = self.streamTag {
                "[\(streamTag)]"
            } else {
                ""
            }
            let formatted = "[\(formattedDateNow)] \(tag) \(message)"
            switch level {
            case .off:
                return
            case .error:
                logger.error("\(formatted)")
            case .warning:
                logger.warning("\(formatted)")
            case .log:
                logger.info("\(formatted)")
            case .debug:
                logger.debug("\(formatted)")
            case .verbose:
                logger.debug("\(formatted)")
            }
         
            logs.insert("\(formatted)\n", at: 0)
            if logs.count > SDKLogger.LOG_SIZE {
                logs.removeLast()
            }
        }
        
    }
    
    func stop() {
        timer?.cancel()
        dispatchQueue.async { [weak self] in
            guard let self else { return }
            self.logs.removeAll()
            self.stats.removeAll()
        }
    }
    
    private func sendToTelemetry() {
        dispatchPrecondition(condition: .onQueue(dispatchQueue))
        guard !(logs.isEmpty && stats.isEmpty) else { return }
        
        let telemetryReport = TelemetryReport(diagnostics: Diagnostics(logs: Array(logs), stats: Array(stats)))
        guard let encodedDiagnostics = try? JSONEncoder().encode(telemetryReport) else {
            logger.error("Failed to encode diagnostics to JSON")
            return
        }
        var request = URLRequest(url: telemetryUrl.appendingPathComponent("/reports"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = encodedDiagnostics
        let task = URLSession.shared.dataTask(with: request) {
            [weak self] data, response, error in
            guard let self else { return }
            if let error {
                self.logger.error("Telemetry returned with error: \(error)")
            }
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    self.logger.info("Telemetry upload succeeded with response: \(httpResponse)")
                } else {
                    
                    self.logger.error("Telemetry upload failed with response: \(httpResponse) and data: \(String(decoding: data ?? Data(), as: UTF8.self))")
                }
                
            }
        }
        task.resume()
    }
}

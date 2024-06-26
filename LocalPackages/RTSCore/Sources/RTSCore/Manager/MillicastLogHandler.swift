//
//  MillicastLogHandler.swift
//

import Foundation
import MillicastSDK
import os

final class MillicastLogHandler: NSObject {
    private static let logger = Logger(
        subsystem: Bundle.module.bundleIdentifier!,
        category: String(describing: MillicastLogHandler.self)
    )
    private var logFilePath: String?

    override init() {
        super.init()
        MCLogger.setDelegate(self)
        MCLogger.setLogLevelWithSdk(.DEBUG, webrtc: .OFF, websocket: .OFF)
    }

    func setLogFilePath(filePath: String?) {
        logFilePath = filePath
    }
}

extension MillicastLogHandler: MCLoggerDelegate {
    func onLog(withMessage message: String, level: MCLogLevel) {
        Self.logger.debug("🪵 onLog - \(message), log-level - \(level.rawValue)")

        guard
            let logFilePath = logFilePath,
            let messageData = "\(String(describing: message))\n".data(using: .utf8)
        else {
            Self.logger.error("🪵 Error writing file - no file path provided")
            return
        }

        let fileURL = URL(fileURLWithPath: logFilePath, isDirectory: false)
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let fileHandle = try FileHandle(forWritingTo: fileURL)
                fileHandle.seekToEndOfFile()
                fileHandle.write(messageData)
                fileHandle.closeFile()
            } else {
                try messageData.write(to: fileURL, options: .atomicWrite)
            }
        } catch {
            Self.logger.error("🪵 Error writing file - \(error.localizedDescription)")
        }
    }
}

//
//  Logger+Utils.swift
//

import OSLog

extension Logger {
    private enum Defaults {
        static let bundleIdentifier = "io.dolby.rtsviewer"
    }

    static func make(category: String) -> Logger {
        Logger(subsystem: Defaults.bundleIdentifier, category: category)
    }
}

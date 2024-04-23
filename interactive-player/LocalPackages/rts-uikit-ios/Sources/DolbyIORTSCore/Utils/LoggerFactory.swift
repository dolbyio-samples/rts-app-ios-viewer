//
//  LoggerFactory.swift
//

import Foundation
import os

extension Logger {
    private enum Defaults {
        static let bundleIdentifier = "io.dolby.rtscore"
    }

    static func make(category: String) -> Logger {
        Logger(subsystem: Defaults.bundleIdentifier, category: category)
    }
}

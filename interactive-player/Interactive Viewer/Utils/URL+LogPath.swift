//
//  URL+LogPath.swift
//  Interactive Player
//
//  Created by Raveendran, Aravind on 16/10/2023.
//

import Foundation

extension URL {
    private static var documentsDirectory: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }

    static func rtcLogPath(for date: Date) -> URL? {
        guard let url = documentsDirectory else {
            return nil
        }

        let timestamp = date.getISO8601TimestampForCurrentDate()
        return url.appendingPathComponent("\(timestamp)_rtcLogs.proto")
    }

    static func sdkLogPath(for date: Date) -> URL? {
        guard let url = documentsDirectory else {
            return nil
        }
        let timestamp = date.getISO8601TimestampForCurrentDate()
        return url.appendingPathComponent("\(timestamp)_sdkLogs.txt")
    }
}

private extension Date {
    func getISO8601TimestampForCurrentDate() -> String {
        let utcISODateFormatter = ISO8601DateFormatter()
        utcISODateFormatter.formatOptions = [.withFullDate, .withFullTime]
        return utcISODateFormatter.string(from: self).replacingOccurrences(of: ":", with: "-")
    }
}

//
//  StatisticsViewModel.swift
//

import Combine
import Foundation
import RTSComponentKit
import UIKit
import SwiftUI

@MainActor
final class StatisticsViewModel: ObservableObject {

    struct StatData: Identifiable {
        var id = UUID()
        var key: LocalizedStringKey
        var value: String
    }

    private let subscriptionManager: SubscriptionManager
    private var subscriptions: [AnyCancellable] = []

    @Published private(set) var statsDataList: [StatData] = []

    init(subscriptionManager: SubscriptionManager) {
        self.subscriptionManager = subscriptionManager

        Task { [weak self] in
            guard let self else { return }
            let subscription = await subscriptionManager.$statistics
                .sink { statisticsReport in
                    guard let statisticsReport else { return }
                    Task {
                        await MainActor.run {
                            self.statsDataList = self.makeStatsList(from: statisticsReport)
                        }
                    }
                }
            self.store(subscription: subscription)
        }
    }

    private func store(subscription: AnyCancellable) {
        subscriptions.append(subscription)
    }
}

// MARK: Stats report parsing
private extension StatisticsViewModel {

    // swiftlint: disable cyclomatic_complexity
    func makeStatsList(from report: StatisticsReport) -> [StatData] {
        var result = [StatData]()

        if let rtt = report.roundTripTime {
            result.append(StatData(key: "stream.stats.rtt.label", value: String(rtt)))
        }
        if let videoResolution = report.video?.videoResolution {
            result.append(StatData(key: "stream.stats.video-resolution.label", value: videoResolution))
        }
        if let fps = report.video?.fps {
            result.append(StatData(key: "stream.stats.fps.label", value: String(fps)))
        }
        if let audioBytesReceived = report.audio?.bytesReceived {
            result.append(StatData(key: "stream.stats.audio-total-received.label", value: formatBytes(bytes: audioBytesReceived)))
        }
        if let videoBytesReceived = report.video?.bytesReceived {
            result.append(StatData(key: "stream.stats.video-total-received.label", value: formatBytes(bytes: videoBytesReceived)))
        }
        if let audioPacketsLost = report.audio?.packetsLost {
            result.append(StatData(key: "stream.stats.audio-packet-loss.label", value: String(audioPacketsLost)))
        }
        if let videoPacketsLost = report.video?.packetsLost {
            result.append(StatData(key: "stream.stats.video-packet-loss.label", value: String(videoPacketsLost)))
        }
        if let audioJitter = report.audio?.jitter {
            result.append(StatData(key: "stream.stats.audio-jitter.label", value: "\(audioJitter)"))
        }
        if let videoJitter = report.video?.jitter {
            result.append(StatData(key: "stream.stats.video-jitter.label", value: "\(videoJitter)"))
        }
        if let timestamp = report.audio?.timestamp {
            result.append(StatData(key: "stream.stats.timestamp.label", value: String(timestamp))) // change to dateStr when timestamp is fixed
        }
        let audioCodec = report.audio?.codecName
        let videoCodec = report.video?.codecName
        if audioCodec != nil || videoCodec != nil {
            var delimiter = ", "
            if audioCodec == nil || videoCodec == nil {
                delimiter = ""
            }
            let codecs = "\(audioCodec ?? "")\(delimiter)\(videoCodec ?? "")"
            result.append(StatData(key: "stream.stats.codecs.label", value: codecs))
        }
        return result
    }
    // swiftlint: enable cyclomatic_complexity

    func dateStr(timestamp: Double) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"

        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        return dateFormatter.string(from: date)
    }

    func formatBytes(bytes: Int) -> String {
        return "\(formatNumber(input: bytes))B"
    }

    func formatBitRate(bitRate: Int) -> String {
        let value = formatNumber(input: bitRate).lowercased()
        return "\(value)bps"
    }

    func formatNumber(input: Int) -> String {
        if input < KILOBYTES { return String(input) }
        if input >= KILOBYTES && input < MEGABYTES { return "\(input / KILOBYTES) K"} else { return "\(input / MEGABYTES) M" }
    }
}

private let KILOBYTES = 1024
private let MEGABYTES = KILOBYTES * KILOBYTES

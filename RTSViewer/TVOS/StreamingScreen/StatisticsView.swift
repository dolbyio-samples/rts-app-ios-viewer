//
//  StatisticsView.swift
//

import DolbyIOUIKit
import SwiftUI
import RTSComponentKit
import Foundation

struct StatisticsView: View {
    @ObservedObject private var viewModel: StatisticsViewModel

    init(dataStore: RTSDataStore) {
        self.viewModel = StatisticsViewModel(dataStore: dataStore)
    }

    private let fontAssetTable = FontAsset.avenirNextRegular(size: FontSize.caption2, style: .caption2)
    private let fontTable = Font.avenirNextRegular(withStyle: .caption2, size: FontSize.caption2)

    private let fontAssetCaption = FontAsset.avenirNextDemiBold(size: FontSize.caption1, style: .caption)
    private let fontAssetTitle = FontAsset.avenirNextBold(size: FontSize.title3, style: .title3)

    var body: some View {
        VStack {
            VStack {
                VStack {
                    HStack {
                        Text(text: "stream.media-stats.label", fontAsset: fontAssetTitle).frame(maxWidth: .infinity, alignment: .leading)
                        Spacer().frame(width: Layout.spacing1x)
                    }.padding([.leading, .top], 40).padding([.bottom], 25)
                    HStack {
                        Text(text: "stream.stats.name.label", fontAsset: fontAssetCaption).frame(maxWidth: 250, alignment: .leading)
                        Text(text: "stream.stats.value.label", fontAsset: fontAssetCaption)
                    }.frame(maxWidth: .infinity, alignment: .leading).padding([.leading, .trailing], 40).padding([.bottom], 10)
                    ForEach(data) { item in
                        HStack {
                            Text(text: item.key, fontAsset: fontAssetTable).frame(maxWidth: 250, alignment: .leading)
                            Text(item.value).font(fontTable)
                        }.frame(maxWidth: .infinity, alignment: .leading).padding([.leading, .trailing], 40)
                    }
                    HStack {
                        Spacer().frame(width: Layout.spacing1x)
                    }.padding([.leading, .top], 40)
                }.background(Color(uiColor: UIColor.Neutral.neutral800)).cornerRadius(Layout.cornerRadius6x)
            }.frame(maxWidth: 700, maxHeight: 700).padding([.leading, .bottom], 35)
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }

    struct StatData: Identifiable {
        var id = UUID()
        var key: LocalizedStringKey
        var value: String
    }

    private var data: [StatData] {
        guard let stats = viewModel.statisticsData else {
            return []
        }

        var result = [StatData]()

        if let rtt = stats.roundTripTime {
            result.append(StatData(key: "stream.stats.rtt.label", value: String(rtt)))
        }
        if let videoResolution = stats.video?.videoResolution {
            result.append(StatData(key: "stream.stats.video-resolution.label", value: videoResolution))
        }
        if let fps = stats.video?.fps {
            result.append(StatData(key: "stream.stats.fps.label", value: String(fps)))
        }
        if let audioBytesReceived = stats.audio?.bytesReceived {
            result.append(StatData(key: "stream.stats.audio-total-received.label", value: formatBytes(bytes: audioBytesReceived)))
        }
        if let videoBytesReceived = stats.video?.bytesReceived {
            result.append(StatData(key: "stream.stats.video-total-received.label", value: formatBytes(bytes: videoBytesReceived)))
        }
        if let audioPacketsLost = stats.audio?.packetsLost {
            result.append(StatData(key: "stream.stats.audio-packet-loss.label", value: String(audioPacketsLost)))
        }
        if let videoPacketsLost = stats.video?.packetsLost {
            result.append(StatData(key: "stream.stats.video-packet-loss.label", value: String(videoPacketsLost)))
        }
        if let audioJitter = stats.audio?.jitter {
            result.append(StatData(key: "stream.stats.audio-jitter.label", value: "\(audioJitter)"))
        }
        if let videoJitter = stats.video?.jitter {
            result.append(StatData(key: "stream.stats.video-jitter.label", value: "\(videoJitter)"))
        }
        if let timestamp = stats.audio?.timestamp {
            result.append(StatData(key: "stream.stats.timestamp.label", value: String(timestamp))) // change to dateStr when timestamp is fixed
        }
        let audioCodec = stats.audio?.codecName
        let videoCodec = stats.video?.codecName
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

    private func dateStr(timestamp: Double) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"

        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        return dateFormatter.string(from: date)
    }

    private func formatBytes(bytes: Int) -> String {
        return "\(formatNumber(input: bytes))B"
    }

    private func formatBitRate(bitRate: Int) -> String {
        let value = formatNumber(input: bitRate).lowercased()
        return "\(value)bps"
    }

    private func formatNumber(input: Int) -> String {
        if input < KILOBYTES { return String(input) }
        if input >= KILOBYTES && input < MEGABYTES { return "\(input / KILOBYTES) K"} else { return "\(input / MEGABYTES) M" }
    }
}

private let KILOBYTES = 1024
private let MEGABYTES = KILOBYTES * KILOBYTES

//
//  StatisticsView.swift
//

import DolbyIOUIKit
import SwiftUI
import RTSComponentKit
import Foundation

public struct StatisticsView: View {
    @Binding var statsView: Bool
    @Binding var stats: StatisticsData?

    private let fontAssetTable = FontAsset.avenirNextRegular(size: FontSize.title3, style: .title3)
    private let fontTable = Font.avenirNextRegular(withStyle: .title3, size: FontSize.title3)

    private let fontAssetCaption = FontAsset.avenirNextDemiBold(size: FontSize.title2, style: .title2)

    public var body: some View {
        VStack {
            VStack {
                VStack {
                    List {
                        HStack {
                            IconButton(name: .close, tintColor: .white) {
                                statsView = false
                            }
                            Spacer().frame(width: Layout.spacing1x)
                        }.frame(maxWidth: .infinity, alignment: .trailing)
                        HStack {
                            Text(text: "stream.media-stats.label", fontAsset: FontAsset.avenirNextBold(size: FontSize.title1, style: .title)).focusable()
                            Spacer().frame(width: Layout.spacing1x)
                        }
                        HStack {
                            Text(text: "stream.stats.name.label", fontAsset: fontAssetCaption).frame(maxWidth: 200, alignment: .leading).focusable()
                            Text(text: "stream.stats.value.label", fontAsset: fontAssetCaption)
                        }
                        if let rtt = stats?.roundTripTime {
                            HStack {
                                Text(text: "stream.stats.rtt.label", fontAsset: fontAssetTable).frame(maxWidth: 200, alignment: .leading).focusable()
                                Text(String(rtt)).font(fontTable)
                            }
                        }
                        if let videoResolution = stats?.video?.videoResolution {
                            HStack {
                                Text(text: "stream.stats.video-resolution.label", fontAsset: fontAssetTable).frame(maxWidth: 200, alignment: .leading).focusable()
                                Text(videoResolution).font(fontTable)
                            }
                        }
                        if let fps = stats?.video?.fps {
                            HStack {
                                Text(text: "stream.stats.fps.label", fontAsset: fontAssetTable).frame(maxWidth: 200, alignment: .leading)
                                Text(String(fps)).font(fontTable)
                            }
                        }
                        if let audioBytesReceived = stats?.audio?.bytesReceived {
                            HStack {
                                Text(text: "stream.stats.audio-total-received.label", fontAsset: fontAssetTable).frame(maxWidth: 200, alignment: .leading).focusable()
                                Text(String(audioBytesReceived)).font(fontTable)
                            }
                        }
                        if let videoBytesReceived = stats?.video?.bytesReceived {
                            HStack {
                                Text(text: "stream.stats.video-total-received.label", fontAsset: fontAssetTable).frame(maxWidth: 200, alignment: .leading)
                                Text(String(videoBytesReceived)).font(fontTable)
                            }
                        }
                        if let audioPacketsLost = stats?.audio?.packetsLost {
                            HStack {
                                Text(text: "stream.stats.audio-packet-loss.label", fontAsset: fontAssetTable).frame(maxWidth: 200, alignment: .leading).focusable()
                                Text(String(audioPacketsLost)).font(fontTable)
                            }
                        }
                        if let videoPacketsLost = stats?.video?.packetsLost {
                            HStack {
                                Text(text: "stream.stats.video-packet-loss.label", fontAsset: fontAssetTable).frame(maxWidth: 200, alignment: .leading).focusable()
                                Text(String(videoPacketsLost)).font(fontTable)
                            }
                        }
                        
                    }.background(Color(uiColor: UIColor.Neutral.neutral800))
                        .onAppear {
                            UITableView.appearance().isScrollEnabled = true
                        }
                }.cornerRadius(Layout.cornerRadius6x)
            }.frame(maxWidth: 700, maxHeight: 700).padding([.leading, .bottom], 35)
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .onExitCommand {
                if statsView {
                    statsView = false
                }
            }
    }
    private func dateStr(timestamp: Double) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"

        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        return dateFormatter.string(from: date)
    }
}

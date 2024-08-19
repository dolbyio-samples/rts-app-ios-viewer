//
//  StatsInfoView.swift
//

import DolbyIOUIKit
import RTSCore
import SwiftUI

struct StatsInfoView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var viewModel: StatsInfoViewModel

    private let fontCaption = Font.custom("AvenirNext-Bold", size: FontSize.subhead)
    private let fontTable = Font.custom("AvenirNext-Regular", size: FontSize.body)
    private let fontTableValue = Font.custom("AvenirNext-DemiBold", size: FontSize.body)
    private let fontTitle = Font.custom("AvenirNext-Bold", size: FontSize.title2)

    init(statsInfoViewModel: StatsInfoViewModel) {
        self.viewModel = statsInfoViewModel
    }

    private var theme: Theme {
        themeManager.theme
    }

    private var pullDownIndicatorView: some View {
        RoundedRectangle(cornerRadius: Layout.cornerRadius4x)
            .fill(Color.gray)
            .frame(width: Layout.spacing6x, height: Layout.spacing1x)
            .padding([.top], Layout.spacing0_5x)
    }

    private var titleView: some View {
        Text("stream.media-stats.label", font: fontTitle)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding([.top, .bottom], Layout.spacing3x)
    }

    var body: some View {
        ScrollView {
            VStack {
                pullDownIndicatorView

                titleView

                HStack {
                    Text("stream.stats.name.label", font: fontCaption)
                        .frame(minWidth: Layout.spacing0x, maxWidth: .infinity, alignment: .leading)

                    Text("stream.stats.value.label", font: fontCaption)
                        .frame(minWidth: Layout.spacing0x, maxWidth: .infinity, alignment: .leading)
                }

                ForEach(viewModel.statsItems) { item in
                    statLabel(for: item.key, value: item.value)
                }
            }
            .padding([.leading, .trailing], Layout.spacing2x)
            .padding(.bottom, Layout.spacing3x)
        }
        .contextMenu {
            Button(action: {
                copyToPasteboard(text: formattedStatisticsText())
            }) {
                Text("stream.stats.copy.label")
                Image(systemName: "doc.on.doc")
            }
        }
    }

    @ViewBuilder
    private func statLabel(for title: String, value: String) -> some View {
        HStack {
            Text(verbatim: title, font: fontTable)
                .foregroundColor(Color(theme.neutral200))
                .frame(minWidth: Layout.spacing0x, maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("Key.\(title)")
                .accessibilityValue(title)
            Text(verbatim: value, font: fontTableValue)
                .foregroundColor(Color(theme.onBackground))
                .frame(minWidth: Layout.spacing0x, maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("Value.\(title)")
                .accessibilityValue("\(value)")
        }
        .padding([.top], Layout.spacing0_5x)
    }

    private func formattedStatisticsText() -> String {
        var text = ""
        viewModel.statsItems.forEach { item in
            text += "\(item.key): \(item.value)\n"
        }
        return text
    }

    private func copyToPasteboard(text: String) {
        UIPasteboard.general.string = text
    }
}

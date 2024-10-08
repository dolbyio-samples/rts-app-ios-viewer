//
//  SettingsMultichannelView.swift
//

import DolbyIOUIKit
import RTSCore
import SwiftUI

struct SettingsMultichannelView: View {
    @State private var showSimulcastView: Bool = false
    @State private var showStatsView: Bool = false
    @Binding private var showSettingsView: Bool

    @FocusState private var focus: FocusableField?

    private let viewModel: SettingsMultichannelViewModel
    private let theme = ThemeManager.shared.theme

    private enum FocusableField: Hashable {
        case simulcastSelection
        case streamStatisticsToggle
    }

    init(
        viewModel: SettingsMultichannelViewModel,
        showSettingsView: Binding<Bool>,
        showStatsView: Bool
    ) {
        self.viewModel = viewModel
        self.showStatsView = showStatsView
        self._showSettingsView = showSettingsView
    }

    var body: some View {
        VStack(alignment: .center) {
            title

            simulcastSelectionView
                .focused($focus, equals: .simulcastSelection)

            statsToggle
                .focused($focus, equals: .streamStatisticsToggle)

            Spacer()
        }
        .padding(Layout.spacing3x)
        .focusSection()
        .frame(maxWidth: UIScreen.main.bounds.size.width / 3)
        .background(Color(uiColor: UIColor.Neutral.neutral800))
        .transition(.move(edge: .trailing))
        .overlay(content: {
            if showSimulcastView {
                let channel = viewModel.channel
                SimulcastView(
                    source: channel.source,
                    videoQualityList: channel.videoQualityList,
                    selectedVideoQuality: channel.selectedVideoQuality
                ) { videoQuality in
                    showSimulcastView = false
                    viewModel.updateSelectedVideoQuality(with: videoQuality)
                    focus = .simulcastSelection
                }
                .onExitCommand {
                    if showSimulcastView {
                        showSimulcastView = false
                        focus = .simulcastSelection
                    }
                }
            }
        })
        .onAppear {
            focus = viewModel.channel.videoQualityList.isEmpty ? .streamStatisticsToggle : .simulcastSelection
        }
        .onExitCommand {
            showSettingsView.toggle()
        }
    }

    private var title: some View {
        HStack {
            Text(
                text: "stream.settings.label",
                mode: .secondary,
                fontAsset: .avenirNextBold(
                    size: FontSize.title3,
                    style: .title3
                )
            )
            .foregroundColor(.white)

            Spacer()
        }
    }

    private var simulcastSelectionView: some View {
        Button(action: {
            showSimulcastView = true
        }, label: {
            HStack(spacing: Layout.spacing0x) {
                let iconColor = Color(uiColor: viewModel.channel.videoQualityList.isEmpty ? .tertiaryLabel : .secondaryLabel)
                IconView(name: .simulcast, tintColor: iconColor)

                Spacer()
                    .frame(width: Layout.spacing2x)

                Text(
                    text: "stream.simulcast.label",
                    mode: .primary,
                    fontAsset: .avenirNextDemiBold(
                        size: FontSize.body,
                        style: .body
                    )
                )

                Text(
                    text: "stream.simulcast.label",
                    mode: viewModel.channel.videoQualityList.isEmpty ? .tertiary : .primary,
                    fontAsset: .avenirNextDemiBold(
                        size: FontSize.body,
                        style: .body
                    )
                )

                Spacer()

                Text(viewModel.channel.selectedVideoQuality.displayText)
                    .font(theme[.avenirNextRegular(size: FontSize.body, style: .body)])
                    .foregroundStyle(viewModel.channel.videoQualityList.isEmpty ? .tertiary : .secondary)

                IconView(name: .chevronRight, tintColor: iconColor)
            }
            .frame(height: Layout.spacing10x)
        })
        .disabled(viewModel.channel.videoQualityList.isEmpty)
    }

    private var statsToggle: some View {
        Toggle(isOn: $showStatsView, label: {
            HStack(spacing: Layout.spacing2x) {
                IconView(name: .info, tintColor: Color(uiColor: .secondaryLabel))
                Text(text: "stream.media-stats.label", mode: .primary, fontAsset: .avenirNextDemiBold(
                    size: FontSize.body,
                    style: .body
                ))
            }
            .frame(height: Layout.spacing10x)
        })
        .onChange(of: showStatsView, perform: { show in
            viewModel.shouldShowStatsView(showStats: show)
        })
        .font(theme[.avenirNextRegular(size: FontSize.body, style: .body)])
    }
}

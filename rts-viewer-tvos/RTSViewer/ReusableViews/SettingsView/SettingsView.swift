//
//  SettingsView.swift
//

import DolbyIOUIKit
import RTSCore
import SwiftUI

struct SettingsView: View {
    private enum FocusableField: Hashable {
        case simulcastSelection
        case streamStatisticsToggle
    }

    private let viewModel: SettingViewModel

    @State private var showSimulcastView: Bool = false

    @Binding private var showStatsView: Bool
    @Binding private var showLiveIndicator: Bool

    @FocusState private var focus: FocusableField?

    private let theme = ThemeManager.shared.theme
    private let onSelectVideoQuality: (StreamSource, VideoQuality) -> Void

    init(
        source: StreamSource,
        showStatsView: Binding<Bool>,
        showLiveIndicator: Binding<Bool>,
        videoQualityList: [VideoQuality],
        selectedVideoQuality: VideoQuality,
        rendererRegistry: RendererRegistry,
        onSelectVideoQuality: @escaping (StreamSource, VideoQuality) -> Void
    ) {
        viewModel = SettingViewModel(
            source: source,
            videoQualityList: videoQualityList,
            selectedVideoQuality: selectedVideoQuality
        )
        _showStatsView = showStatsView
        _showLiveIndicator = showLiveIndicator
        self.onSelectVideoQuality = onSelectVideoQuality
    }

    var body: some View {
        VStack(alignment: .center) {
            title

            simulcastSelectionView
                .focused($focus, equals: .simulcastSelection)

            statsToggle
                .focused($focus, equals: .streamStatisticsToggle)

            liveIndicatorToggle

            Spacer()
        }
        .padding(Layout.spacing3x)
        .focusSection()
        .frame(maxWidth: UIScreen.main.bounds.size.width / 3)
        .background(Color(uiColor: UIColor.Neutral.neutral800))
        .transition(.move(edge: .trailing))
        .overlay {
            if showSimulcastView {
                SimulcastView(
                    source: viewModel.source,
                    videoQualityList: viewModel.videoQualityList,
                    selectedVideoQuality: viewModel.selectedVideoQuality) { videoQuality in
                        showSimulcastView = false
                        onSelectVideoQuality(viewModel.source, videoQuality)
                        focus = .simulcastSelection
                    }
                    .onExitCommand {
                        if showSimulcastView {
                            showSimulcastView = false
                            focus = .simulcastSelection
                        }
                    }
            }
        }
        .onAppear {
            focus = viewModel.videoQualityList.isEmpty ? .streamStatisticsToggle : .simulcastSelection
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
                let iconColor = Color(uiColor: viewModel.videoQualityList.isEmpty ? .tertiaryLabel : .secondaryLabel)
                IconView(name: .simulcast, tintColor: iconColor)

                Spacer()
                    .frame(width: Layout.spacing2x)

                Text(
                    text: "stream.simulcast.label",
                    mode: viewModel.videoQualityList.isEmpty ? .tertiary : .primary,
                    fontAsset: .avenirNextDemiBold(
                        size: FontSize.body,
                        style: .body
                    )
                )

                Spacer()

                Text(viewModel.selectedVideoQuality.displayText)
                    .font(theme[.avenirNextRegular(size: FontSize.body, style: .body)])
                    .foregroundStyle(viewModel.videoQualityList.isEmpty ? .tertiary : .secondary)

                IconView(name: .chevronRight, tintColor: iconColor)
            }
            .frame(height: Layout.spacing10x)
        })
        .disabled(viewModel.videoQualityList.isEmpty)
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
        .font(theme[.avenirNextRegular(size: FontSize.body, style: .body)])
    }

    private var liveIndicatorToggle: some View {
        Toggle(isOn: $showLiveIndicator, label: {
            HStack(spacing: Layout.spacing2x) {
                IconView(name: .liveStream, tintColor: Color(uiColor: .secondaryLabel))
                Text(text: "stream.live-indicator.label", mode: .primary, fontAsset: .avenirNextDemiBold(
                    size: FontSize.body,
                    style: .body
                ))
            }
            .frame(height: Layout.spacing10x)
        })
        .font(theme[.avenirNextRegular(size: FontSize.body, style: .body)])
    }
}

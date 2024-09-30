//
//  SettingsMultichannelView.swift
//

import DolbyIOUIKit
import RTSCore
import SwiftUI

struct SettingsMultichannelView: View {
    @State private var showSimulcastView: Bool = false
    @Binding private var overlayIsFocused: Bool
    @Binding private var showStatsView: Bool
//    @Binding private var returnFocus: Channel?
    @FocusState private var focus: FocusableField?

    private let viewModel: SettingMultichannelViewModel
    private let theme = ThemeManager.shared.theme
    private let onSelectVideoQuality: (Channel, VideoQuality) -> Void

    private enum FocusableField: Hashable {
        case simulcastSelection
        case streamStatisticsToggle
    }

    init(
        viewModel: SettingMultichannelViewModel,
        overlayIsFocused: Binding<Bool>,
        showStatsView: Binding<Bool>,
        onSelectVideoQuality: @escaping (Channel, VideoQuality) -> Void
    ) {
        self.viewModel = viewModel
        self._showStatsView = showStatsView
        self._overlayIsFocused = overlayIsFocused
        self.onSelectVideoQuality = onSelectVideoQuality
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
//        .overlay {
//            if showSimulcastView {
//                SimulcastView(
//                    source: viewModel.source,
//                    videoQualityList: viewModel.videoQualityList,
//                    selectedVideoQuality: viewModel.selectedVideoQuality
//                ) { videoQuality in
//                    showSimulcastView = false
//                    onSelectVideoQuality(viewModel.channel.source, videoQuality)
//                    focus = .simulcastSelection
//                }
//                .onExitCommand {
//                    if showSimulcastView {
//                        showSimulcastView = false
//                        focus = .simulcastSelection
//                    }
//                }
//            }
//        }
        .onAppear {
            focus = .simulcastSelection
//            focus = viewModel.videoQualityList.isEmpty ? .streamStatisticsToggle : .simulcastSelection
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
//                let iconColor = Color(uiColor: viewModel.videoQualityList.isEmpty ? .tertiaryLabel : .secondaryLabel)
                let iconColor = Color(uiColor: .secondaryLabel)
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

//                Text(
//                    text: "stream.simulcast.label",
//                    mode: viewModel.videoQualityList.isEmpty ? .tertiary : .primary,
//                    fontAsset: .avenirNextDemiBold(
//                        size: FontSize.body,
//                        style: .body
//                    )
//                )

                Spacer()

//                Text(viewModel.selectedVideoQuality.displayText)
//                    .font(theme[.avenirNextRegular(size: FontSize.body, style: .body)])
//                    .foregroundStyle(viewModel.videoQualityList.isEmpty ? .tertiary : .secondary)

                IconView(name: .chevronRight, tintColor: iconColor)
            }
            .frame(height: Layout.spacing10x)
        })
//        .disabled(viewModel.videoQualityList.isEmpty)
        .disabled(true)
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
}

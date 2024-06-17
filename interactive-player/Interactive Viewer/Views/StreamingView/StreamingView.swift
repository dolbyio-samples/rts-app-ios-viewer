//
//  StreamingView.swift
//

import SwiftUI
import RTSCore
import DolbyIOUIKit

struct StreamingView: View {
    struct Context: Identifiable {
        let id = UUID()
        let streamDetail: StreamDetail
        let listViewPrimaryVideoQuality: VideoQuality
        let configuration: SubscriptionConfiguration

        init(
            streamName: String,
            accountID: String,
            listViewPrimaryVideoQuality: VideoQuality,
            configuration: SubscriptionConfiguration
        ) {
            self.streamDetail = StreamDetail(streamName: streamName, accountID: accountID)
            self.listViewPrimaryVideoQuality = listViewPrimaryVideoQuality
            self.configuration = configuration
        }
    }

    @StateObject private var viewModel: StreamViewModel
    @State private var isShowingSettingsScreen: Bool = false
    @State private var isShowingDetailSingleViewScreen: Bool = false

    @ObservedObject private var themeManager = ThemeManager.shared

    private let onClose: () -> Void
    private var theme: Theme { themeManager.theme }

    init(context: Context, onClose: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: StreamViewModel(context: context))
        self.onClose = onClose
    }

    @ViewBuilder
    private func singleStreamView(
        with sources: [StreamSource],
        selectedVideoSource: StreamSource,
        selectedAudioSource: StreamSource?,
        showSourceLabels: Bool,
        isShowingDetailPresentation: Bool = false
    ) -> some View {
        SingleStreamView(
            sources: sources,
            selectedVideoSource: selectedVideoSource,
            selectedAudioSource: selectedAudioSource,
            settingsMode: viewModel.settingsMode,
            subscriptionManager: viewModel.subscriptionManager,
            isShowingDetailPresentation: isShowingDetailPresentation,
            videoTracksManager: viewModel.videoTracksManager,
            onSelect: {
                viewModel.selectVideoSource($0)
            },
            onClose: {
                if isShowingDetailPresentation {
                    isShowingDetailSingleViewScreen = false
                }
            }
        )
    }

    @ViewBuilder
    private var singleStreamDetailView: some View {
        switch viewModel.state {
        case let .success(displayMode: _, sources: sources, selectedVideoSource: selectedVideoSource, selectedAudioSource: selectedAudioSource, settings: settings):
            singleStreamView(
                with: sources,
                selectedVideoSource: selectedVideoSource,
                selectedAudioSource: selectedAudioSource,
                showSourceLabels: settings.showSourceLabels,
                isShowingDetailPresentation: true
            )
        default:
            EmptyView()
        }
    }

    // swiftlint:disable function_body_length
    @ViewBuilder
    private func streamView(
        for displayMode: StreamViewModel.DisplayMode,
        sources: [StreamSource],
        selectedVideoSource: StreamSource,
        selectedAudioSource: StreamSource?,
        showSourceLabels: Bool
    ) -> some View {
        ZStack {
            switch displayMode {
            case .list:
                ListView(
                    sources: sources,
                    selectedVideoSource: selectedVideoSource,
                    selectedAudioSource: selectedAudioSource,
                    showSourceLabels: showSourceLabels,
                    isShowingDetailView: isShowingDetailSingleViewScreen,
                    mainTilePreferredVideoQuality: viewModel.listViewPrimaryVideoQuality, subscriptionManager: viewModel.subscriptionManager,
                    videoTracksManager: viewModel.videoTracksManager,
                    onPrimaryVideoSelection: { _ in
                        isShowingDetailSingleViewScreen = true
                    },
                    onSecondaryVideoSelection: {
                        viewModel.selectVideoSource($0)
                    }
                )
            case .single:
                singleStreamView(
                    with: sources,
                    selectedVideoSource: selectedVideoSource,
                    selectedAudioSource: selectedAudioSource,
                    showSourceLabels: showSourceLabels
                )

            case .grid:
                GridView(
                    sources: sources,
                    selectedVideoSource: selectedVideoSource,
                    selectedAudioSource: selectedAudioSource,
                    showSourceLabels: showSourceLabels,
                    isShowingDetailView: isShowingDetailSingleViewScreen,
                    subscriptionManager: viewModel.subscriptionManager,
                    videoTracksManager: viewModel.videoTracksManager,
                    onVideoSelection: {
                        viewModel.selectVideoSource($0)
                        isShowingDetailSingleViewScreen = true
                    }
                )
            }
        }
        .overlay(alignment: .topLeading) {
            if shouldShowLiveIndicatorView {
                liveIndicatorView
            }
        }
        .toolbar {
            closeToolbarItem
            titleToolBarItem
            settingsToolbarItem
        }
    }
    // swiftlint:enable function_body_length

    @ViewBuilder
    private func errorView(title: String, subtitle: String?) -> some View {
        ErrorView(title: title, subtitle: subtitle)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .topTrailing) {
                closeButton
            }
            .overlay(alignment: .topLeading) {
                if shouldShowLiveIndicatorView {
                    liveIndicatorView
                }
            }
    }

    @ViewBuilder
    private var closeButton: some View {
        IconButton(iconAsset: .close) {
            onClose()
            viewModel.endStream()
        }
        .background(Color(uiColor: theme.neutral400))
        .clipShape(Circle().inset(by: Layout.spacing0_5x))
    }

    @ViewBuilder
    private var progressView: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar {
                closeToolbarItem
                titleToolBarItem
            }
    }

    @ViewBuilder
    private var liveIndicatorView: some View {
        let isStreamActive: Bool = switch viewModel.state {
        case .success:
            true
        default:
            false
        }

        LiveIndicatorView(isStreamActive: isStreamActive)
            .padding(Layout.spacing0_5x)
    }

    private var titleToolBarItem: ToolbarItem<(), some View> {
        ToolbarItem(placement: .principal) {
            let streamName = viewModel.streamDetail.streamName
            Text(
                verbatim: streamName,
                font: .custom("AvenirNext-Regular", size: FontSize.subhead, relativeTo: .subheadline)
            ).accessibilityIdentifier("StreamingScreenTitle.\(streamName)")
        }
    }

    private var closeToolbarItem: ToolbarItem<(), some View> {
        ToolbarItem(placement: .navigationBarLeading) {
            IconButton(iconAsset: .close) {
                onClose()
                viewModel.endStream()
            }
        }
    }

    private var settingsToolbarItem: ToolbarItem<(), some View> {
        ToolbarItem(placement: .navigationBarTrailing) {
            SettingsButton { isShowingSettingsScreen = true }
                .accessibilityIdentifier("StreamingScreen.SettingButton")
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                NavigationLink(
                    destination: singleStreamDetailView,
                    isActive: $isShowingDetailSingleViewScreen
                ) {
                    EmptyView()
                }
                .hidden()

                NavigationLink(
                    destination: SettingsScreen(mode: viewModel.settingsMode),
                    isActive: $isShowingSettingsScreen
                ) {
                    EmptyView()
                }.hidden()

                switch viewModel.state {
                case let .success(displayMode: displayMode, sources: sources, selectedVideoSource: selectedVideoSource, selectedAudioSource: selectedAudioSource, settings: settings):
                    streamView(
                        for: displayMode,
                        sources: sources,
                        selectedVideoSource: selectedVideoSource,
                        selectedAudioSource: selectedAudioSource,
                        showSourceLabels: settings.showSourceLabels
                    )
                case .loading:
                    progressView
                case let .error(title: title, subtitle: subtitle):
                    errorView(title: title, subtitle: subtitle)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            viewModel.viewStream()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    private var shouldShowLiveIndicatorView: Bool {
        switch viewModel.state {
        case let .success(displayMode: displayMode, sources: _, selectedVideoSource: _, selectedAudioSource: _, settings: _):
            switch displayMode {
            case .list:
                true
            case .grid:
                true
            case .single:
                false
            }

        default:
            true
        }
    }

}

//
//  SingleStreamView.swift
//

import DolbyIOUIKit
import MillicastSDK
import RTSCore
import SwiftUI

struct SingleStreamView: View {
    private enum Animation {
        static let duration: CGFloat = 0.75
        static let blendDuration: CGFloat = 3.0
        static let offset: CGFloat = 200.0
    }

    private let isShowingDetailPresentation: Bool
    private let onSelect: (StreamSource) -> Void
    private let onClose: (() -> Void)?
    private var viewModel: SingleStreamViewModel

    @State private var showingScreenControls = false
    @State private var isShowingSettingsScreen: Bool = false
    @State private var isShowingStatsInfoScreen: Bool = false
    @State private var selectedVideoStreamSourceId: UUID

    @StateObject private var userInteractionViewModel: UserInteractionViewModel = .init()

    @ObservedObject private var themeManager = ThemeManager.shared

    init(
        sources: [StreamSource],
        selectedVideoSource: StreamSource,
        selectedAudioSource: StreamSource?,
        settingsMode: SettingsMode,
        subscriptionManager: SubscriptionManager,
        isShowingDetailPresentation: Bool,
        videoTracksManager: VideoTracksManager,
        onSelect: @escaping (StreamSource) -> Void,
        onClose: (() -> Void)? = nil
    ) {
        self.isShowingDetailPresentation = isShowingDetailPresentation
        self.onSelect = onSelect
        self.onClose = onClose
        let viewModel = SingleStreamViewModel(
            sources: sources,
            selectedVideoSource: selectedVideoSource,
            selectedAudioSource: selectedAudioSource,
            settingsMode: settingsMode,
            subscriptionManager: subscriptionManager,
            videoTracksManager: videoTracksManager
        )
        _selectedVideoStreamSourceId = State(wrappedValue: viewModel.selectedVideoSource.id)
        self.viewModel = viewModel
    }

    private var theme: Theme {
        themeManager.theme
    }

    @ViewBuilder
    private var topToolBarView: some View {
        HStack {
            LiveIndicatorView(isStreamActive: true)
            Spacer()
            if isShowingDetailPresentation {
                closeButton
            }
        }
        .ignoresSafeArea()
        .padding(Layout.spacing1x)
    }

    @ViewBuilder
    private var bottomToolBarView: some View {
        HStack {
            StatsInfoButton { isShowingStatsInfoScreen.toggle() }

            Spacer()

            if isShowingDetailPresentation {
                SettingsButton { isShowingSettingsScreen = true }
            }
        }
        .ignoresSafeArea()
        .padding(Layout.spacing1x)
    }

    @ViewBuilder
    private var closeButton: some View {
        IconButton(iconAsset: .close) {
            onClose?()
        }
        .background(Color(uiColor: theme.neutral400))
        .clipShape(Circle().inset(by: Layout.spacing0_5x))
    }

    var body: some View {
        ZStack {
            NavigationLink(
                destination: SettingsScreen(mode: viewModel.settingsMode),
                isActive: $isShowingSettingsScreen
            ) {
                EmptyView()
            }.hidden()

            GeometryReader { proxy in
                TabView(selection: $selectedVideoStreamSourceId) {
                    ForEach(viewModel.sources, id: \.id) { source in
                        let maxAllowedVideoWidth = proxy.size.width
                        let maxAllowedVideoHeight = proxy.size.height
                        let displayLabel = source.sourceId.displayLabel
                        let preferredVideoQuality: VideoQuality = .auto
                        let isSelectedVideoSource = source == viewModel.selectedVideoSource
                        let isSelectedAudioSource = source == viewModel.selectedAudioSource
                        let viewId = "\(SingleStreamView.self).\(displayLabel)"

                        VideoRendererView(
                            source: source,
                            isSelectedVideoSource: isSelectedVideoSource,
                            isSelectedAudioSource: isSelectedAudioSource,
                            isPiPView: isSelectedVideoSource,
                            showSourceLabel: false,
                            showAudioIndicator: false,
                            maxWidth: maxAllowedVideoWidth,
                            maxHeight: maxAllowedVideoHeight,
                            accessibilityIdentifier: "SingleStreamViewVideoTile.\(displayLabel)",
                            preferredVideoQuality: .auto,
                            subscriptionManager: viewModel.subscriptionManager,
                            videoTracksManager: viewModel.videoTracksManager,
                            action: { _ in
                                // No-op
                            }
                        )
                        .tag(source.id)
                        .onAppear {
                            SingleStreamViewModel.logger.debug("♼ Single stream view: Video view appear for \(source.sourceId)")
                            Task {
                                await viewModel.videoTracksManager.enableTrack(for: source, with: preferredVideoQuality, on: viewId)
                            }
                        }
                        .onDisappear {
                            SingleStreamViewModel.logger.debug("♼ Single stream view: Video view disappear for \(source.sourceId)")
                            Task {
                                await viewModel.videoTracksManager.disableTrack(for: source, on: viewId)
                            }
                        }
                        .id(source.id)
                    }
                }
                .tabViewStyle(.page)
                .overlay(alignment: .top) {
                    topToolBarView
                        .offset(x: 0, y: showingScreenControls ? 0 : -Animation.offset)
                }
                .overlay(alignment: .bottom) {
                    bottomToolBarView
                        .offset(x: 0, y: showingScreenControls ? 0 : Animation.offset)
                }
                .sheet(isPresented: $isShowingStatsInfoScreen) {
                    statisticsView()
                }
                .onAppear {
                    showControlsAndObserveInteractions()
                }
                .onReceive(userInteractionViewModel.interactivityTimer) { _ in
                    guard isShowingDetailPresentation else {
                        return
                    }
                    hideControlsAndStopObservingInteractions()
                }
                .onTapGesture {
                    guard isShowingDetailPresentation else {
                        return
                    }
                    if showingScreenControls {
                        hideControlsAndStopObservingInteractions()
                    } else {
                        showControlsAndObserveInteractions()
                    }
                }
                .onChange(of: selectedVideoStreamSourceId) { newValue in
                    guard let selectedStreamSource = viewModel.streamSource(for: newValue) else {
                        return
                    }
                    onSelect(selectedStreamSource)
                }
            }
            .navigationBarHidden(isShowingDetailPresentation)
        }
    }

    private func statisticsView() -> some View {
        HStack {
            StatisticsInfoView(statsInfoViewModel: viewModel.statsInfoViewModel)

            Spacer()
        }
        .frame(alignment: Alignment.bottom)
    }

    private func showControlsAndObserveInteractions() {
        withAnimation(.spring(blendDuration: Animation.blendDuration)) {
            showingScreenControls = true
        }
        guard isShowingDetailPresentation else {
            return
        }
        userInteractionViewModel.startInteractivityTimer()
    }

    private func hideControlsAndStopObservingInteractions() {
        withAnimation(.easeOut(duration: Animation.duration)) {
            showingScreenControls = false
        }
        userInteractionViewModel.stopInteractivityTimer()
    }
}

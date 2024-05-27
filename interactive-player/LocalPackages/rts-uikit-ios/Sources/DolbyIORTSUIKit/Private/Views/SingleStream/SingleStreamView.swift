//
//  SingleStreamView.swift
//

import SwiftUI
import DolbyIORTSCore
import DolbyIOUIKit

struct SingleStreamView: View {

    private enum Animation {
        static let duration: CGFloat = 0.75
        static let blendDuration: CGFloat = 3.0
        static let offset: CGFloat = 200.0
    }

    private let viewModel: SingleStreamViewModel
    private let isShowingDetailPresentation: Bool
    private let onSelect: ((StreamSource) -> Void)
    private let onClose: (() -> Void)?

    @State private var showScreenControls = false
    @State private var selectedVideoStreamSourceId: UUID
    @State private var isShowingSettingsScreen: Bool = false
    @State private var isShowingStatsInfoScreen: Bool = false
    @State private var deviceOrientation: UIDeviceOrientation = UIDeviceOrientation.portrait

    @StateObject private var userInteractionViewModel: UserInteractionViewModel = .init()

    @ObservedObject private var themeManager = ThemeManager.shared

    init(
        viewModel: SingleStreamViewModel,
        isShowingDetailPresentation: Bool,
        onSelect: @escaping (StreamSource) -> Void,
        onClose: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.isShowingDetailPresentation = isShowingDetailPresentation
        self.onSelect = onSelect
        self.onClose = onClose
        _selectedVideoStreamSourceId = State(wrappedValue: viewModel.selectedVideoSource.id)
    }

    private var theme: Theme {
        themeManager.theme
    }

    @ViewBuilder
    private var topToolBarView: some View {
        HStack {
            LiveIndicatorView()
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
                destination: LazyNavigationDestinationView(
                    SettingsScreen(mode: viewModel.settingsMode)
                ),
                isActive: $isShowingSettingsScreen
            ) {
                EmptyView()
            }.hidden()

            GeometryReader { proxy in
                TabView(selection: $selectedVideoStreamSourceId) {
                    ForEach(viewModel.videoViewModels, id: \.streamSource.id) { videoRendererViewModel in
                        let maxAllowedVideoWidth = proxy.size.width
                        let maxAllowedVideoHeight = proxy.size.height
                        VideoRendererView(
                            viewModel: videoRendererViewModel,
                            viewRenderer: viewModel.viewRendererProvider.renderer(for: videoRendererViewModel.streamSource, isPortait: deviceOrientation.isPortrait),
                            maxWidth: maxAllowedVideoWidth,
                            maxHeight: maxAllowedVideoHeight,
                            contentMode: .aspectFit,
                            identifier: "SingleStreamViewVideoTile.\(videoRendererViewModel.streamSource.sourceId.displayLabel)"
                        )
                        .tag(videoRendererViewModel.streamSource.id)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .overlay(alignment: .top) {
                    topToolBarView
                        .offset(x: 0, y: showScreenControls ? 0 : -Animation.offset)
                }
                .overlay(alignment: .bottom) {
                    bottomToolBarView
                        .offset(x: 0, y: showScreenControls ? 0 : Animation.offset)
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
                    if showScreenControls {
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
        .onRotate { newOrientation in
            if !newOrientation.isFlat && newOrientation.isValidInterfaceOrientation {
                deviceOrientation = newOrientation
            }
        }
    }

    private func statisticsView() -> some View {
        return HStack {
            StatisticsInfoView(viewModel: StatsInfoViewModel(streamSource: viewModel.selectedVideoSource))
            Spacer()
        }
        .frame(alignment: Alignment.bottom)
        .edgesIgnoringSafeArea(.all)
    }

    private func showControlsAndObserveInteractions() {
        withAnimation(.spring(blendDuration: Animation.blendDuration)) {
            showScreenControls = true
        }
        guard isShowingDetailPresentation else {
            return
        }
        userInteractionViewModel.startInteractivityTimer()
    }

    private func hideControlsAndStopObservingInteractions() {
        withAnimation(.easeOut(duration: Animation.duration)) {
            showScreenControls = false
        }
        userInteractionViewModel.stopInteractivityTimer()
    }
}

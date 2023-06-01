//
//  SingleStreamView.swift
//

import SwiftUI
import DolbyIORTSCore
import DolbyIOUIKit

struct SingleStreamView: View {
    @ObservedObject private var viewModel: StreamViewModel
    @State private var showScreenControls = false
    @State private var selectedVideoStreamSourceId: UUID
    @State private var isShowingSettingsScreen: Bool = false
    @State private var streamId: String?

    private let isShowingDetailPresentation: Bool
    private let onClose: (() -> Void)?

    private enum Animation {
        static let duration: CGFloat = 0.75
        static let blendDuration: CGFloat = 3.0
        static let offset: CGFloat = 200.0
    }

    init(viewModel: StreamViewModel,
         isShowingDetailPresentation: Bool = false,
         onClose: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.isShowingDetailPresentation = isShowingDetailPresentation
        self.onClose = onClose
        _selectedVideoStreamSourceId = State(wrappedValue: viewModel.selectedVideoStreamSourceId!)
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
        if let source = viewModel.selectedVideoSource {
            HStack {
                StatsInfoButton(streamSource: source)

                Spacer()

                if isShowingDetailPresentation {
                    SettingsButton(isShowingSettingsScreen: $isShowingSettingsScreen)
                }
            }
            .ignoresSafeArea()
            .padding(Layout.spacing1x)
        }
    }

    @ViewBuilder
    private var closeButton: some View {
        IconButton(name: .close) {
            onClose?()
        }
        .background(Color(uiColor: UIColor.Neutral.neutral400))
        .clipShape(Circle().inset(by: Layout.spacing0_5x))
    }

    var body: some View {
        ZStack {
            NavigationLink(destination: LazyNavigationDestinationView(SettingsScreen()),
                           isActive: $isShowingSettingsScreen
            ) {
                EmptyView()
            }.hidden()

            GeometryReader { proxy in
                TabView(selection: $selectedVideoStreamSourceId) {
                    ForEach(viewModel.sortedSources, id: \.id) { source in
                        if let viewProvider = viewModel.mainViewProvider(for: source) {
                            let maxAllowedVideoWidth = proxy.size.width
                            let maxAllowedVideoHeight = proxy.size.height

                            let videoSize = viewProvider.videoViewDisplaySize(
                                forAvailableScreenWidth: maxAllowedVideoWidth,
                                availableScreenHeight: maxAllowedVideoHeight,
                                shouldCrop: false
                            )

                            HStack {
                                VideoRendererView(viewProvider: viewProvider)
                                    .frame(width: videoSize.width, height: videoSize.height)
                                    .onAppear {
                                        viewModel.playVideo(for: source)
                                        viewModel.playAudio(for: source)
                                    }
                                    .onDisappear {
                                        viewModel.stopAudio(for: source)
                                        viewModel.stopVideo(for: source)
                                    }
                            }
                            .tag(source.id)
                            .frame(width: proxy.size.width, height: proxy.size.height)
                        }
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
                .onAppear {
                    showControlsAndObserveInteractions()
                }
                .onReceive(viewModel.interactivityTimer) { _ in
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
                    viewModel.selectVideoSourceWithId(newValue)
                }
            }
            .navigationBarHidden(isShowingDetailPresentation)
        }
    }

    private func showControlsAndObserveInteractions() {
        withAnimation(.spring(blendDuration: Animation.blendDuration)) {
            showScreenControls = true
        }
        guard isShowingDetailPresentation else {
            return
        }
        viewModel.startInteractivityTimer()
    }

    private func hideControlsAndStopObservingInteractions() {
        withAnimation(.easeOut(duration: Animation.duration)) {
            showScreenControls = false
        }
        viewModel.stopInteractivityTimer()
    }
}

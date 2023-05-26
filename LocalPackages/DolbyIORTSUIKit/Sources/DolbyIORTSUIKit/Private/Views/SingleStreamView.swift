//
//  SingleStreamView.swift
//

import SwiftUI
import DolbyIORTSCore
import DolbyIOUIKit

struct SingleStreamView: View {
    @ObservedObject private var viewModel: StreamViewModel
    @State private var showScreenControls = false
    @State private var currentIndex: Int = 0
    private let isShowingDetailPresentation: Bool
    private let onClose: (() -> Void)?

    private enum Animation {
        static let duration: CGFloat = 0.75
        static let blendDuration: CGFloat = 3.0
        static let offset: CGFloat = 200.0
    }

    init(viewModel: StreamViewModel, isShowingDetailPresentation: Bool = false, onClose: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.isShowingDetailPresentation = isShowingDetailPresentation
        self.onClose = onClose
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
                    SettingsButton()
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
        GeometryReader { proxy in
            TabView(selection: $currentIndex) {
                ForEach(
                    0..<viewModel.allSources.count,
                    id: \.self) { index in
                        let source = viewModel.allSources[index]
                        HStack {
                            if let viewProvider = viewModel.mainViewProvider(for: source) {
                                let maxAllowedVideoWidth = proxy.size.width
                                let maxAllowedVideoHeight = proxy.size.height

                                let videoSize = viewProvider.videoViewDisplaySize(
                                    forAvailableScreenWidth: maxAllowedVideoWidth,
                                    availableScreenHeight: maxAllowedVideoHeight,
                                    shouldCrop: false
                                )

                                VideoRendererView(viewProvider: viewProvider)
                                    .frame(width: videoSize.width, height: videoSize.height)
                                    .onAppear {
                                        viewModel.playVideo(for: source)
                                        viewModel.playAudio(for: source)
                                    }
                            }
                        }
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .tag(index)
                    }
            }
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
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .onChange(of: currentIndex) { newValue in
            viewModel.selectVideoSourceAtIndex(newValue)
        }
        .navigationBarHidden(isShowingDetailPresentation)
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

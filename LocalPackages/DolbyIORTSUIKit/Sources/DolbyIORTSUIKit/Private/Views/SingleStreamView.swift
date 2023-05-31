//
//  SingleStreamView.swift
//

import SwiftUI
import DolbyIORTSCore
import DolbyIOUIKit

struct SingleStreamView: View {
    private let viewModel: SingleStreamViewModel
    @State private var showScreenControls = false
//    @State private var selectedVideoStreamSourceId: UUID
    private let isShowingDetailPresentation: Bool
    private let onClose: (() -> Void)?
    @State private var currentState: Int = 0

    private enum Animation {
        static let duration: CGFloat = 0.75
        static let blendDuration: CGFloat = 3.0
        static let offset: CGFloat = 200.0
    }

    init(viewModel: SingleStreamViewModel, isShowingDetailPresentation: Bool, onClose: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.isShowingDetailPresentation = isShowingDetailPresentation
        self.onClose = onClose
//        _selectedVideoStreamSourceId = State(wrappedValue: viewModel.selectedVideoStreamSourceId!)
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
        EmptyView()
//        if let source = viewModel.selectedVideoSource {
//            HStack {
//                StatsInfoButton(streamSource: source)
//                Spacer()
//                if isShowingDetailPresentation {
//                    SettingsButton()
//                        .padding(Layout.spacing1x)
//                }
//            }
//            .ignoresSafeArea()
//            .padding(Layout.spacing1x)
//        }
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
            TabView(selection: $currentState) {
                ForEach(viewModel.videoViewModels, id: \.streamSource.id) { viewModel in
                    let maxAllowedVideoWidth = proxy.size.width
                    let maxAllowedVideoHeight = proxy.size.height

                    HStack {
                        VideoRendererView(
                            viewModel: viewModel,
                            maxWidth: maxAllowedVideoWidth,
                            maxHeight: maxAllowedVideoHeight,
                            contentMode: .aspectFit
                        )
                    }
                    .tag(viewModel.streamSource.id)
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
            .onAppear {
                showControlsAndObserveInteractions()
            }
//            .onReceive(viewModel.interactivityTimer) { _ in
//                guard isShowingDetailPresentation else {
//                    return
//                }
//                hideControlsAndStopObservingInteractions()
//            }
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
//            .onChange(of: selectedVideoStreamSourceId) { newValue in
//                viewModel.selectVideoSourceWithId(newValue)
//            }
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
//        viewModel.startInteractivityTimer()
    }

    private func hideControlsAndStopObservingInteractions() {
        withAnimation(.easeOut(duration: Animation.duration)) {
            showScreenControls = false
        }
//        viewModel.stopInteractivityTimer()
    }
}

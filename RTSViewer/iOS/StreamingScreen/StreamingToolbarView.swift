//
//  StreamingToolbarView.swift
//

import DolbyIOUIKit
import Foundation
import SwiftUI
import RTSComponentKit

struct StreamingToolbarView: View {
    private enum Constants {
        static let timeOutConstant: CGFloat = 5.0
        static let easeOutAnimationDuration: CGFloat = 0.75
        static let animateInBlendDuration: CGFloat = 3.0
        static let animationOffset: CGFloat = 200.0
    }

    @ObservedObject private var viewModel: StreamToolbarViewModel

    @Binding var showSettings: Bool
    @Binding var showToolbar: Bool
    @Binding var showStats: Bool
    @Binding var showFullScreen: Bool

    let showSimulcast: Bool
    let onChangeFullScreen: (Bool) -> Void
    @EnvironmentObject private var appState: AppState

    @State private var showScreenControls = false
    @State private var interactivityTimer = Timer.publish(every: Constants.timeOutConstant, on: .main, in: .common).autoconnect()

    init(viewModel: StreamToolbarViewModel, showSimulcast: Bool, showSettings: Binding<Bool>, showToolbar: Binding<Bool>, showStats: Binding<Bool>, showFullScreen: Binding<Bool>, onChangeFullScreen: @escaping (Bool) -> Void) {
        self.viewModel = viewModel
        self.showSimulcast = showSimulcast
        self.onChangeFullScreen = onChangeFullScreen

        _showSettings = showSettings
        _showToolbar = showToolbar
        _showStats = showStats
        _showFullScreen = showFullScreen
    }

    var body: some View {
        ZStack {
            VStack {
                ZStack {
                    HStack {
                        Text(text: viewModel.isStreamActive ? "stream.live.label" : "stream.offline.label",
                             fontAsset: .avenirNextBold(
                                size: FontSize.caption2,
                                style: .caption2
                             )
                        )
                        .padding(.leading, 20)
                        .padding(.trailing, 20)
                        .padding(.top, 6)
                        .padding(.bottom, 6)
                        .background(
                            viewModel.isStreamActive ?
                            Color(uiColor: UIColor.Feedback.error500) :
                                Color(uiColor: UIColor.Neutral.neutral400)
                        )
                        .cornerRadius(Layout.cornerRadius6x)

                        Text(viewModel.streamName ?? "")
                    }.frame(maxWidth: .infinity, alignment: .leading)

                    HStack {
                        VStack {
                            IconButton(
                                name: .close
                            ) {
                                if !showSettings && !showStats {
                                    appState.popToRootView()
                                } else {
                                    showSettings = false
                                    showStats = false
                                }
                            }
                            .background(Color(uiColor: UIColor.Neutral.neutral400))
                            .clipShape(Circle())

                        }.frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                HStack {
                    if !showFullScreen {
                        IconButton(
                            name: .fullScreen
                        ) {
                            if !showSettings && !showStats {
                                showFullScreen = true
                                onChangeFullScreen(showFullScreen)
                            } else {
                                showSettings = false
                                showStats = false
                            }
                        }
                    }
                    if showFullScreen {
                        IconButton(
                            name: .exitFullScreen
                        ) {
                            if !showSettings && !showStats {
                                showFullScreen = false
                                onChangeFullScreen(false)
                            } else {
                                showSettings = false
                                showStats = false
                            }
                        }
                    }
                }.frame(maxWidth: .infinity, alignment: .trailing)
            }
            .offset(x: 0, y: showScreenControls ? 0 : -Constants.animationOffset)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(maxHeight: .infinity, alignment: .top)
            .padding([.all], 10)

            if viewModel.isStreamActive {
                HStack {
                    IconButton(
                        name: .info
                    ) {
                        withAnimation {
                            showStats = !showStats
                        }
                    }

                    if showSimulcast {
                        HStack {
                            IconButton(
                                name: .more
                            ) {
                                withAnimation {
                                    showSettings = !showSettings
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .offset(x: 0, y: showScreenControls ? 0 : Constants.animationOffset)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding([.all], 10)
                .transition(.move(edge: .bottom))
            }
        }
        .contentShape(Rectangle())
        .background(Color.black.opacity(showScreenControls ? 0.5 : 0.0))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            showControlsAndObserveInteractions()
        }
        .onReceive(interactivityTimer) { _ in
            hideControlsAndStopObservingInteractions()
        }
        .onTapGesture {
            if showScreenControls {
                hideControlsAndStopObservingInteractions()
            } else {
                showControlsAndObserveInteractions()
            }
        }
    }

    private func showControlsAndObserveInteractions() {
        withAnimation(.spring(blendDuration: Constants.animateInBlendDuration)) {
            showScreenControls = true
        }
        interactivityTimer = Timer.publish(every: Constants.timeOutConstant, on: .main, in: .common).autoconnect()
    }

    private func hideControlsAndStopObservingInteractions() {
        withAnimation(.easeOut(duration: Constants.easeOutAnimationDuration)) {
            showScreenControls = false
        }
        interactivityTimer.upstream.connect().cancel()
    }
}

struct RemoveBackgroundColor: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        return UIView()
    }
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            uiView.superview?.superview?.backgroundColor = .clear
        }
    }
}

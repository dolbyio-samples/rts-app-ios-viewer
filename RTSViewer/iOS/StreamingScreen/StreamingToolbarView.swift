//
//  StreamingToolbarView.swift
//

import DolbyIOUIKit
import Foundation
import SwiftUI
import RTSComponentKit

struct StreamingToolbarView: View {
    @ObservedObject private var viewModel: StreamToolbarViewModel

    @Binding var showSettings: Bool
    @Binding var showToolbar: Bool
    @Binding var showStats: Bool

    let showSimulcast: Bool
    @EnvironmentObject private var appState: AppState

    @State private var showScreenControls = false
    @State private var interactivityTimer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()

    init(viewModel: StreamToolbarViewModel, showSimulcast: Bool, showSettings: Binding<Bool>, showToolbar: Binding<Bool>, showStats: Binding<Bool>) {
        self.viewModel = viewModel
        self.showSimulcast = showSimulcast

        _showSettings = showSettings
        _showToolbar = showToolbar
        _showStats = showStats
    }

    var body: some View {
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
                if viewModel.isLiveIndicatorEnabled {
                    HStack {
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
                        Spacer().frame(width: Layout.spacing1x)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .offset(x: 0, y: showScreenControls ? 0 : -200)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.leading, 16)
            .padding(.top, 27)

            if viewModel.isStreamActive {
                HStack {
                    Spacer().frame(width: Layout.spacing1x)
                    IconButton(
                        name: .info
                    ) {
                        withAnimation {
                            showStats = !showStats
                        }
                    }.popover(isPresented: $showStats, attachmentAnchor: .point(.bottom)) {
                        StatisticsView(dataStore: viewModel.dataStore)
                            .background(RemoveBackgroundColor())
                            .ignoresSafeArea(.all)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
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
                            Spacer().frame(width: Layout.spacing1x)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .offset(x: 0, y: showScreenControls ? 0 : 200)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding()
                .transition(.move(edge: .bottom))
            }
        }
        .contentShape(Rectangle())
        .background(Color.black.opacity(showScreenControls ? 0.5 : 0.0))
        .ignoresSafeArea(.all)
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
        withAnimation(.spring(blendDuration: 3.0)) {
            showScreenControls = true
        }
        interactivityTimer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    }

    private func hideControlsAndStopObservingInteractions() {
        withAnimation(.easeOut(duration: 0.75)) {
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

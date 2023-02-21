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
                ).padding(.leading, 20)
                    .padding(.trailing, 20)
                    .padding(.top, 6)
                    .padding(.bottom, 6)
                    .background(viewModel.isStreamActive ? Color(uiColor: UIColor.Feedback.error500) : Color(uiColor: UIColor.Neutral.neutral400))
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
                    }.frame(maxWidth: .infinity, alignment: .trailing)
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
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
                    }.popover(isPresented: $showStats) {
                        StatisticsView(dataStore: viewModel.dataStore)
                            .background(RemoveBackgroundColor())
                            .presentationDetents([.fraction(0.6), .large])
                            .presentationDragIndicator(.visible)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background {
                                Rectangle().fill(Color(uiColor: .Neutral.neutral900).opacity(0.7))
                                    .ignoresSafeArea(.container, edges: .all)
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
                            Spacer().frame(width: Layout.spacing1x)
                        }.frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding()
                .transition(.move(edge: .bottom))
            }
        }
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

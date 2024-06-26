//
//  StreamingView.swift
//

import DolbyIOUIKit
import SwiftUI
import RTSCore
import Network
import MillicastSDK

struct StreamingView: View {

    @StateObject private var viewModel: StreamingViewModel

    @State private var showSettingsView = false
    @State private var showStatsView = false

    @Environment(\.dismiss) var dismiss

    init(subscriptionManager: SubscriptionManager) {
        _viewModel = StateObject(wrappedValue: StreamingViewModel(subscriptionManager: subscriptionManager))
    }

    private func makeBackgroundView(@ViewBuilder content: () -> some View, opacity: CGFloat) -> some View {
        VStack {
            content()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .opacity(opacity)
    }

    var body: some View {
        BackgroundContainerView {
            ZStack {
                switch viewModel.state {
                case let .streaming(source: source):
                    VideoView(renderer: viewModel.rendererRegistry.acceleratedRenderer(for: source))
                        .overlay(alignment: .bottomTrailing) {
                            SettingsButton {
                                withAnimation {
                                    showSettingsView = true
                                }
                            }
                            .padding()
                        }
                        .onAppear {
                            Task {
                                try await viewModel.videoViewDidAppear()
                            }
                        }
                        .overlay(alignment: .bottomLeading) {
                            if showStatsView {
                                StatisticsView(source: source, subscriptionManager: viewModel.subscriptionManager)
                            }
                        }
                        .overlay(alignment: .trailing) {
                            if showSettingsView {
                                SettingsView(
                                    source: source,
                                    showStatsView: $showStatsView,
                                    showLiveIndicator: Binding(get: {
                                        viewModel.isLiveIndicatorEnabled
                                    }, set: {
                                        viewModel.updateLiveIndicator($0)
                                    }),
                                    videoQualityList: viewModel.videoQualityList,
                                    selectedVideoQuality: viewModel.selectedVideoQuality,
                                    rendererRegistry: viewModel.rendererRegistry,
                                    onUpdateSelectedVideoQuality: {
                                        viewModel.selectedVideoQuality = $0
                                    }
                                )
                            }
                        }
                case .loading, .stopped:
                    GeometryReader { proxy in
                        LoadingView()
                            .frame(width: proxy.size.width, height: proxy.size.height)
                    }

                case let .noNetwork(title: title):
                    ErrorView(title: title, subtitle: nil)
                case let .streamNotPublished(title: title, subtitle: subtitle, source: _):
                    ErrorView(title: title, subtitle: subtitle)
                case .otherError(message: let message):
                    ErrorView(title: message, subtitle: nil)
                }
            }
            .overlay(alignment: .topLeading) {
                // swiftlint: disable switch_case_alignment
                let isStreamLive = switch viewModel.state {
                case .streaming:
                    true
                default:
                    false
                }
                // swiftlint: enable switch_case_alignment

                if viewModel.isLiveIndicatorEnabled {
                    LiveIndicatorView(isStreamLive: isStreamLive)
                        .padding()
                }
            }
            .edgesIgnoringSafeArea(.all)
            .onReceive(viewModel.$state) { _ in
                switch viewModel.state {
                case .streaming:
                    UIApplication.shared.isIdleTimerDisabled = true
                default:
                    UIApplication.shared.isIdleTimerDisabled = false
                }
            }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            Task {
                try await viewModel.stopSubscribe()
            }
        }
        .navigationBarHidden(true)
        .onExitCommand {
            if showSettingsView {
                showSettingsView = false
            } else {
                dismiss()
            }
        }
    }
}

#if DEBUG
struct StreamingView_Previews: PreviewProvider {
    static var previews: some View {
        StreamingView(subscriptionManager: SubscriptionManager())
    }
}
#endif

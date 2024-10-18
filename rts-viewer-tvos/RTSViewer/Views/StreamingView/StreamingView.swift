//
//  StreamingView.swift
//

import DolbyIOUIKit
import MillicastSDK
import Network
import RTSCore
import SwiftUI

struct StreamingView: View {
    @StateObject private var viewModel: StreamingViewModel

    @State private var showSettingsView = false
    @State private var showStatsView = false
    @State var viewSize: CGSize = .zero

    @Environment(\.dismiss) var dismiss

    init(streamName: String, accountID: String, playoutDelay: PlayoutDelay) {
        _viewModel = StateObject(wrappedValue: StreamingViewModel(streamName: streamName, accountID: accountID, playoutDelay: playoutDelay))
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
                case let .streaming(source: source, _, _):
                    VideoRendererView(
                        source: source,
                        showSourceLabel: false,
                        showAudioIndicator: false,
                        maxWidth: viewSize.width,
                        maxHeight: viewSize.height,
                        accessibilityIdentifier: "\(VideoRendererView.self)",
                        rendererRegistry: viewModel.rendererRegistry
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .sizePreferenceModifier()
                    .onPreferenceChange(SizePreferenceKey.self) {
                        viewSize = $0
                    }
                    .overlay(alignment: .bottomTrailing) {
                        SettingsButton {
                            withAnimation {
                                showSettingsView = true
                            }
                        }
                        .padding()
                        .opacity(0)
                    }
                    .overlay(alignment: .bottomLeading) {
                        if showStatsView,
                           let streamStatistics = viewModel.streamStatistics,
                           let mid = source.videoTrack?.currentMID ?? source.audioTrack?.currentMID {
                            StatisticsView(
                                source: source,
                                streamStatistics: streamStatistics,
                                layers: viewModel.videoQualityList.compactMap {
                                    switch $0 {
                                    case .auto:
                                        return nil
                                    case let .quality(layer):
                                        return layer
                                    }
                                },
                                projectedTimeStamp: viewModel.projectedTimeStampForMids[mid]
                            )
                            .frame(maxWidth: viewSize.width * 0.5, maxHeight: viewSize.height * 0.9, alignment: .bottomLeading)
                            .padding()
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
                                onSelectVideoQuality: { source, videoQuality in
                                    viewModel.select(videoQuality: videoQuality, for: source)
                                }
                            )
                        }
                    }
                case .disconnected:
                    LoadingView()
                case let .noNetwork(title: title):
                    ErrorView(title: title, subtitle: nil)
                case let .streamNotPublished(title: title, subtitle: subtitle, source: _):
                    ErrorView(title: title, subtitle: subtitle)
                case let .otherError(message: message):
                    ErrorView(title: message, subtitle: nil)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .onAppear {
            viewModel.subscribeToStream()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            viewModel.stopSubscribe()
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
            StreamingView(streamName: "StreamName", accountID: "AccountID", playoutDelay: PlayoutDelay())
        }
    }
#endif

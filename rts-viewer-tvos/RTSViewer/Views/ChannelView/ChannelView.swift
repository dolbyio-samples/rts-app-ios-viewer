//
//  ChannelView.swift
//

 import DolbyIOUIKit
 import RTSCore
 import SwiftUI

 struct ChannelView: View {
    @ObservedObject private var viewModel: ChannelViewModel
    @ObservedObject private var themeManager = ThemeManager.shared

    private var theme: Theme { themeManager.theme }

    init(viewModel: ChannelViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            ZStack {
                switch viewModel.state {
                case let .success(channels: channels):
                    let viewModel = ChannelGridViewModel(channels: channels)
                    ChannelGridView(viewModel: viewModel)
                case .loading:
                    progressView
                case let .error(title: title, subtitle: subtitle, showLiveIndicator: showLiveIndicator):
                    errorView(title: title, subtitle: subtitle, showLiveIndicator: showLiveIndicator)
                }
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            viewModel.viewStreams()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            viewModel.endStream()
        }
    }

    @ViewBuilder
    private func errorView(title: String, subtitle: String?, showLiveIndicator: Bool) -> some View {
        ErrorView(title: title, subtitle: subtitle)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var progressView: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
 }

 #Preview {
     ChannelView(viewModel: ChannelViewModel(unsourcedChannels: .constant([]), onClose: {}))
 }

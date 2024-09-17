////
////  ChannelView.swift
////
//    
//
// import DolbyIOUIKit
// import RTSCore
// import SwiftUI
//
// struct ChannelView: View {
//    @ObservedObject private var viewModel: ChannelViewModel
//    @ObservedObject private var themeManager = ThemeManager.shared
//
//    private let onClose: () -> Void
//    private var theme: Theme { themeManager.theme }
//
//    init(viewModel: ChannelViewModel, onClose: @escaping () -> Void) {
//        self.viewModel = viewModel
//        self.onClose = onClose
//    }
//
//    var body: some View {
//        NavigationView {
//            ZStack {
//                switch viewModel.state {
//                case let .success(channels: channels):
//                    let viewModel = ChannelGridViewModel(channels: channels)
//                    ChannelGridView(viewModel: viewModel)
//                        .toolbar {
//                            closeToolbarItem
//                        }
//                case .loading:
//                    progressView
//                case let .error(title: title, subtitle: subtitle, showLiveIndicator: showLiveIndicator):
//                    errorView(title: title, subtitle: subtitle, showLiveIndicator: showLiveIndicator)
//                }
//            }
//            .navigationBarTitleDisplayMode(.inline)
//            .navigationBarBackButtonHidden(true)
//        }
//        .onAppear {
//            UIApplication.shared.isIdleTimerDisabled = true
//            viewModel.viewStreams()
//        }
//        .onDisappear {
//            UIApplication.shared.isIdleTimerDisabled = false
//        }
//    }
//
//    @ViewBuilder
//    private func errorView(title: String, subtitle: String?, showLiveIndicator: Bool) -> some View {
//        ErrorView(title: title, subtitle: subtitle)
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//            .overlay(alignment: .topTrailing) {
//                closeButton
//            }
//    }
//
//    @ViewBuilder
//    private var closeButton: some View {
//        IconButton(iconAsset: .close) {
//            onClose()
//            viewModel.endStream()
//        }
//        .background(Color(uiColor: theme.neutral400))
//        .clipShape(Circle().inset(by: Layout.spacing0_5x))
//        .accessibilityIdentifier("\(StreamingView.self).CloseButton")
//    }
//
//    @ViewBuilder
//    private var progressView: some View {
//        ProgressView()
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//            .toolbar {
//                closeToolbarItem
//            }
//    }
//
//    private var closeToolbarItem: ToolbarItem<Void, some View> {
//        ToolbarItem(placement: .navigationBarLeading) {
//            IconButton(iconAsset: .close) {
//                onClose()
//                viewModel.endStream()
//            }
//        }
//    }
// }
//
// #Preview {
//    ChannelView(viewModel: ChannelViewModel(channels: .constant([])), onClose: {})
// }

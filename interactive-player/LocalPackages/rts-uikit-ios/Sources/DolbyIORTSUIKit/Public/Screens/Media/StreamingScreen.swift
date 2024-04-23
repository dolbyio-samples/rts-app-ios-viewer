//
//  StreamingScreen.swift
//

import SwiftUI
import DolbyIORTSCore
import DolbyIOUIKit

public struct StreamingScreen: View {

    public struct Context: Identifiable {
        public let id = UUID()
        public let streamDetail: StreamDetail
        public let listViewPrimaryVideoQuality: VideoQuality

        public init(streamName: String, accountID: String, listViewPrimaryVideoQuality: VideoQuality) {
            self.streamDetail = StreamDetail(streamName: streamName, accountID: accountID)
            self.listViewPrimaryVideoQuality = listViewPrimaryVideoQuality
        }
    }

    @StateObject private var viewModel: StreamViewModel
    @State private var isShowingSettingsScreen: Bool = false
    @ObservedObject private var themeManager = ThemeManager.shared

    private let onClose: () -> Void

    private var theme: Theme { themeManager.theme }

    public init(
        context: Context,
        listViewPrimaryVideoQuality: VideoQuality = .auto,
        onClose: @escaping () -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: .init(
                context: context,
                listViewPrimaryVideoQuality: listViewPrimaryVideoQuality
            )
        )
        self.onClose = onClose
    }

    @ViewBuilder
    private var singleStreamDetailView: some View {
        if let singleStreamUiState = viewModel.detailSingleStreamViewModel {
            SingleStreamView(
                viewModel: singleStreamUiState,
                isShowingDetailPresentation: true,
                onSelect: {
                    viewModel.selectVideoSource($0)
                },
                onClose: {
                    viewModel.isShowingDetailSingleViewScreen = false
                }
            )
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func streamView(for displayMode: StreamViewModel.DisplayMode) -> some View {
        ZStack {
            switch displayMode {
            case let .list(listViewModel):
                ListView(
                    viewModel: listViewModel,
                    onPrimaryVideoSelection: { _ in
                        viewModel.isShowingDetailSingleViewScreen = true
                    },
                    onSecondaryVideoSelection: {
                        viewModel.selectVideoSource($0)
                    }
                )
            case let .single(SingleStreamViewModel):
                SingleStreamView(
                    viewModel: SingleStreamViewModel,
                    isShowingDetailPresentation: false,
                    onSelect: {
                        viewModel.selectVideoSource($0)
                    }
                )
            case let .grid(gridViewModel):
                GridView(
                    viewModel: gridViewModel,
                    onVideoSelection: {
                        viewModel.selectVideoSource($0)
                        viewModel.isShowingDetailSingleViewScreen = true
                    }
                )
            }
        }
        .overlay(alignment: .topLeading) {
            liveIndicatorView
        }
        .toolbar {
            closeToolbarItem
            titleToolBarItem
            settingsToolbarItem
        }
    }

    @ViewBuilder
    private func errorView(for viewModel: ErrorViewModel) -> some View {
        ErrorView(viewModel: viewModel)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .topTrailing) {
                closeButton
            }
            .overlay(alignment: .topLeading) {
                liveIndicatorView
            }
    }

    @ViewBuilder
    private var closeButton: some View {
        IconButton(iconAsset: .close) {
            endStream()
        }
        .background(Color(uiColor: theme.neutral400))
        .clipShape(Circle().inset(by: Layout.spacing0_5x))
    }

    @ViewBuilder
    private var progressView: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar {
                closeToolbarItem
                titleToolBarItem
            }
    }

    @ViewBuilder
    private var liveIndicatorView: some View {
        let shouldShowLiveIndicatorView: Bool = {
            switch viewModel.state {
            case let .success(displayMode: displayMode):
                switch displayMode {
                case .list: return true
                case .grid: return true
                case .single: return false
                }
            default: return true
            }
        }()
        if shouldShowLiveIndicatorView {
            LiveIndicatorView()
                .padding(Layout.spacing0_5x)
        } else {
            EmptyView()
        }
    }

    private var titleToolBarItem: ToolbarItem<(), some View> {
        ToolbarItem(placement: .principal) {
            let streamName = viewModel.streamDetail.streamName
            Text(
                verbatim: streamName,
                font: .custom("AvenirNext-Regular", size: FontSize.subhead, relativeTo: .subheadline)
            )
        }
    }

    private var closeToolbarItem: ToolbarItem<(), some View> {
        ToolbarItem(placement: .navigationBarLeading) {
            IconButton(iconAsset: .close) {
                endStream()
            }
        }
    }

    private var settingsToolbarItem: ToolbarItem<(), some View> {
        ToolbarItem(placement: .navigationBarTrailing) {
            SettingsButton { isShowingSettingsScreen = true }
        }
    }

    public var body: some View {
        NavigationView {
            ZStack {
                NavigationLink(
                    destination: LazyNavigationDestinationView(
                        singleStreamDetailView
                    ),
                    isActive: $viewModel.isShowingDetailSingleViewScreen
                ) {
                    EmptyView()
                }
                .hidden()

                NavigationLink(
                    destination: LazyNavigationDestinationView(
                        SettingsScreen(mode: viewModel.settingsMode)
                    ),
                    isActive: $isShowingSettingsScreen
                ) {
                    EmptyView()
                }.hidden()

                switch viewModel.state {
                case let .success(displayMode: displayMode):
                    streamView(for: displayMode)
                case .loading:
                    progressView
                case let .error(errorViewModel):
                    errorView(for: errorViewModel)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
}

// MARK: Helper functions

extension StreamingScreen {
    func endStream() {
        onClose()
        Task {
            try await viewModel.endStream()
        }
    }
}

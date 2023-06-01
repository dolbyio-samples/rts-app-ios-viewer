//
//  StreamingScreen.swift
//

import SwiftUI
import DolbyIORTSCore
import DolbyIOUIKit

public struct StreamingScreen: View {
    @StateObject private var viewModel: StreamViewModel = .init()
    @Binding private var isShowingStreamView: Bool
    @State private var isShowingSingleViewScreen: Bool = false
    @State private var isShowingSettingsScreen: Bool = false
    @State private var streamId: String?

    private let settingsManager: SettingsManager

    public init(isShowingStreamView: Binding<Bool>,
                settingManager: SettingsManager = .shared) {
        _isShowingStreamView = isShowingStreamView
        self.settingsManager = settingManager
    }

    public var body: some View {
        ZStack {
            NavigationLink(
                destination: LazyNavigationDestinationView(
                    SingleStreamView(
                        viewModel: viewModel,
                        isShowingDetailPresentation: true
                    ) {
                        isShowingSingleViewScreen = false
                    }
                ),
                isActive: $isShowingSingleViewScreen
            ) {
                EmptyView()
            }
            .hidden()

            NavigationLink(destination: LazyNavigationDestinationView(SettingsScreen()),
                           isActive: $isShowingSettingsScreen
            ) {
                EmptyView()
            }.hidden()

            switch viewModel.mode {
            case .list:
                ListView(viewModel: viewModel) {
                    isShowingSingleViewScreen = true
                }
            case .single:
                SingleStreamView(viewModel: viewModel)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                BackButton {
                    endStream()
                }
            }
            ToolbarItem(placement: .principal) {
                // TODO: Add title
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if let streamId = viewModel.sortedSources.first?.streamId {
                    SettingsButton {
                        if self.streamId == nil {
                            settingsManager.setActiveSetting(for: .stream(streamID: streamId))
                            self.streamId = streamId
                        }
                        isShowingSettingsScreen = true
                    }
                }
            }
        }
    }
}

// MARK: Helper functions

extension StreamingScreen {
    func endStream() {
        Task {
            await viewModel.endStream()
            _isShowingStreamView.wrappedValue = false
        }
    }
}

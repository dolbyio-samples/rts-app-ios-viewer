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

    public init(isShowingStreamView: Binding<Bool>) {
        _isShowingStreamView = isShowingStreamView
    }

    @ViewBuilder
    private var singleStreamView: some View {
        if let detailSingleStreamViewModel = viewModel.detailSingleStreamViewModel {
            SingleStreamView(
                viewModel: detailSingleStreamViewModel,
                isShowingDetailPresentation: true,
                onSelect: {
                    viewModel.selectVideoSource($0)
                },
                onClose: {
                    isShowingSingleViewScreen = false
                }
            )
        } else {
            EmptyView()
        }
    }

    public var body: some View {
        ZStack {
            NavigationLink(
                destination: LazyNavigationDestinationView(
                    singleStreamView
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

            switch viewModel.state {
            case let .success(displayMode: displayMode):
                switch displayMode {
                case let .list(listViewModel):
                    ListView(
                        viewModel: listViewModel,
                        onPrimaryVideoSelection: { _ in
                            isShowingSingleViewScreen = true
                        },
                        onSecondaryVideoSelection: {
                            viewModel.selectVideoSource($0)
                        }
                    )
                case let .single(singleStreamViewModel):
                    SingleStreamView(
                        viewModel: singleStreamViewModel,
                        isShowingDetailPresentation: false,
                        onSelect: {
                            viewModel.selectVideoSource($0)
                        }
                    )
                }
            case .loading:
                // TODO: Handle loading state
                EmptyView()
            case .error:
                // TODO: Handle error state
                EmptyView()
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
                if let streamName = viewModel.streamDetail?.streamName {
                    SwiftUI.Text(streamName)
                        .font(.avenirNextRegular(withStyle: .title, size: FontSize.subhead))
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                SettingsButton { isShowingSettingsScreen = true }
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

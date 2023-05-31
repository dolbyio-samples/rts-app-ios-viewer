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

    public init(isShowingStreamView: Binding<Bool>) {
        _isShowingStreamView = isShowingStreamView
    }

    public var body: some View {
        ZStack {
//            NavigationLink(
//                destination: LazyNavigationDestinationView(
//                    SingleStreamView(
//                        viewModel: viewModel,
//                        isShowingDetailPresentation: true
//                    ) {
//                        isShowingSingleViewScreen = false
//                    }
//                ),
//                isActive: $isShowingSingleViewScreen
//            ) {
//                EmptyView()
//            }
//            .hidden()

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
                    SingleStreamView(viewModel: singleStreamViewModel, isShowingDetailPresentation: false)
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
                // TODO: Add title
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                SettingsButton()
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

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

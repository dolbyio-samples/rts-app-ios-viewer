//
//  SettingsScreen.swift
//

import SwiftUI
import DolbyIOUIKit

public struct SettingsScreen: View {

    @Environment(\.presentationMode) var presentationMode

    public let title: LocalizedStringKey
    @ObservedObject private var viewModel: StreamSettingsViewModel

    @State private var isShowingMultiviewScreen: Bool = false
    @State private var isShowingStreamSortOrderScreen: Bool = false
    @State private var isShowingAudioSelectionScreen: Bool = false

    public enum Mode {
        case global
        case stream
    }

    public init(mode: Mode = .stream,
                viewModel: StreamSettingsViewModel) {
        switch mode {
        case .global: title = "settings.global.title.label"
        default: title = "settings.stream.title.label"
        }
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack(alignment: Alignment(horizontal: .center, vertical: .top)) {
            NavigationLink(
                destination: LazyNavigationDestinationView(SettingsMultiviewScreen(viewModel)),
                isActive: $isShowingMultiviewScreen) {
                    EmptyView()
                }
                .hidden()

            NavigationLink(
                destination: LazyNavigationDestinationView(SettingsStreamSortorderScreen(viewModel)),
                isActive: $isShowingStreamSortOrderScreen) {
                    EmptyView()
                }
                .hidden()

            NavigationLink(
                destination: LazyNavigationDestinationView(SettingsAudioSelectionScreen(viewModel)),
                isActive: $isShowingAudioSelectionScreen) {
                    EmptyView()
                }
                .hidden()

            List {
                Toggle("Show source labels", isOn: Binding<Bool>(
                    get: { viewModel.showSourceLabels },
                    set: { viewModel.setShowSourceLabels($0) })
                )

                SettingsCell(text: "settings.default-multiview-layout.label",
                             textColor: .white,
                             value: .init(viewModel.multiviewLayout.rawValue),
                             valueColor: .gray,
                             image: .textLink,
                             bundle: .module,
                             action: { isShowingMultiviewScreen = true }
                )

                SettingsCell(text: "settings.stream-sort-order.label",
                             textColor: .white,
                             value: .init(viewModel.streamSortOrder.rawValue),
                             image: .textLink,
                             bundle: .module,
                             action: { isShowingStreamSortOrderScreen = true }
                )

                SettingsCell(text: "settings.audio-selection.label",
                             textColor: .white,
                             value: .init(viewModel.audioSelection.name),
                             image: .textLink,
                             bundle: .module,
                             action: { isShowingAudioSelectionScreen = true }
                )
            }
            .navigationBarBackButtonHidden()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title, bundle: .module)
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    IconButton(name: .chevronLeft, tintColor: .white, action: {
                        presentationMode.wrappedValue.dismiss()
                    })
                }
            }
            .listStyle(.plain)
        }
    }
}

struct SettingsScreen_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SettingsScreen(viewModel: .init())
        }
    }
}

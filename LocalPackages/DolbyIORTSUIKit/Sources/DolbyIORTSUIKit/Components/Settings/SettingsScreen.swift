//
//  SettingsScreen.swift
//

import SwiftUI
import DolbyIOUIKit

public struct SettingsScreen: View {

    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: SettingsViewModel = .init()

    @State private var isShowingMultiviewScreen: Bool = false
    @State private var isShowingStreamSortOrderScreen: Bool = false
    @State private var isShowingAudioSelectionScreen: Bool = false

    public init() {

    }

    public var body: some View {
        ZStack(alignment: Alignment(horizontal: .center, vertical: .top)) {
            NavigationLink(
                destination: LazyNavigationDestinationView(SettingsMultiviewScreen(viewModel: viewModel)),
                isActive: $isShowingMultiviewScreen) {
                    EmptyView()
                }
                .hidden()

            NavigationLink(
                destination: LazyNavigationDestinationView(SettingsStreamSortorderScreen(viewModel: viewModel)),
                isActive: $isShowingStreamSortOrderScreen) {
                    EmptyView()
                }
                .hidden()

            NavigationLink(
                destination: LazyNavigationDestinationView(SettingsAudioSelectionScreen(viewModel: viewModel)),
                isActive: $isShowingAudioSelectionScreen) {
                    EmptyView()
                }
                .hidden()

            List {
                Toggle(isOn: Binding<Bool>(
                    get: { viewModel.showSourceLabels },
                    set: { viewModel.setShowSourceLabels($0) })
                ) {
                    Text(
                        text: "settings.show-source-labels.label",
                        bundle: .module,
                        mode: .primary,
                        fontAsset: .avenirNextRegular(
                            size: CGFloat(14.0),
                            style: .body
                        )
                    )
                }

                SettingsCell(text: "settings.default-multiview-layout.label",
                             textColor: .white,
                             value: viewModel.mutliviewSelectedLabelKey,
                             valueColor: .gray,
                             image: .textLink,
                             bundle: .module,
                             action: { isShowingMultiviewScreen = true }
                )

                SettingsCell(text: "settings.stream-sort-order.label",
                             textColor: .white,
                             value: viewModel.streamSortOrderSelectedLabelKey,
                             image: .textLink,
                             bundle: .module,
                             action: { isShowingStreamSortOrderScreen = true }
                )

                SettingsCell(text: "settings.audio-selection.label",
                             textColor: .white,
                             value: viewModel.audioSelectedLabelKey,
                             image: .textLink,
                             bundle: .module,
                             action: { isShowingAudioSelectionScreen = true }
                )
            }
            .navigationBarBackButtonHidden()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(viewModel.settingsScreenTitle, bundle: .module)
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
            SettingsScreen()
        }
    }
}

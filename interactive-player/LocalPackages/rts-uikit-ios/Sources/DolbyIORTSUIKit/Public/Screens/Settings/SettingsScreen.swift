//
//  SettingsScreen.swift
//

import SwiftUI
import DolbyIOUIKit

public struct SettingsScreen<Content: View>: View {

    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: SettingsViewModel

    @State private var isShowingMultiviewScreen: Bool = false
    @State private var isShowingStreamSortOrderScreen: Bool = false
    @State private var isShowingAudioSelectionScreen: Bool = false

    @ViewBuilder private let moreSettings: Content

    public init(mode: SettingsMode, @ViewBuilder moreSettings: () -> Content) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(mode: mode))
        self.moreSettings = moreSettings()
    }

    public init(mode: SettingsMode) where Content == EmptyView {
        self.init(mode: mode) {
            EmptyView()
        }
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
                destination: LazyNavigationDestinationView(SettingsStreamSortOrderScreen(viewModel: viewModel)),
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
                moreSettings

                Toggle(isOn: Binding<Bool>(
                    get: { viewModel.showSourceLabels },
                    set: { viewModel.setShowSourceLabels($0) })
                ) {
                    Text(
                        "settings.show-source-labels.label",
                        bundle: .module,
                        style: .titleMedium,
                        font: .custom("AvenirNext-Regular", size: FontSize.body)
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
            .environment(\.defaultMinListRowHeight, Layout.spacing6x)
            .navigationBarBackButtonHidden()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(viewModel.settingsScreenTitle, bundle: .module)
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    IconButton(iconAsset: .chevronLeft, tintColor: .white, action: {
                        presentationMode.wrappedValue.dismiss()
                    })
                    .accessibilityIdentifier("SettingsScreen.BackIconButton")
                }
            }
            .listStyle(.plain)
        }
    }
}

struct SettingsScreen_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SettingsScreen(mode: .global)
        }
    }
}

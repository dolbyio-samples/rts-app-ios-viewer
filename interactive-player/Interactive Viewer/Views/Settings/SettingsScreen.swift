//
//  SettingsScreen.swift
//

import SwiftUI
import DolbyIOUIKit

struct SettingsScreen<Content: View>: View {

    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: SettingsViewModel

    @State private var isShowingMultiviewScreen: Bool = false
    @State private var isShowingStreamSortOrderScreen: Bool = false
    @State private var isShowingAudioSelectionScreen: Bool = false

    @ViewBuilder private let moreSettings: Content

    init(mode: SettingsMode, @ViewBuilder moreSettings: () -> Content) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(mode: mode))
        self.moreSettings = moreSettings()
    }

    init(mode: SettingsMode) where Content == EmptyView {
        self.init(mode: mode) {
            EmptyView()
        }
    }

    var body: some View {
        ZStack(alignment: Alignment(horizontal: .center, vertical: .top)) {
            NavigationLink(
                destination: SettingsMultiviewScreen(viewModel: viewModel),
                isActive: $isShowingMultiviewScreen) {
                    EmptyView()
                }
                .hidden()

            NavigationLink(
                destination: SettingsStreamSortOrderScreen(viewModel: viewModel),
                isActive: $isShowingStreamSortOrderScreen) {
                    EmptyView()
                }
                .hidden()

            NavigationLink(
                destination: SettingsAudioSelectionScreen(viewModel: viewModel),
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
                        bundle: .main,
                        style: .titleMedium,
                        font: .custom("AvenirNext-Regular", size: FontSize.body)
                    )
                }

                SettingsCell(text: "settings.default-multiview-layout.label",
                             textColor: .white,
                             value: viewModel.mutliviewSelectedLabelKey,
                             valueColor: .gray,
                             image: .textLink,
                             bundle: .main,
                             action: { isShowingMultiviewScreen = true }
                )

                SettingsCell(text: "settings.stream-sort-order.label",
                             textColor: .white,
                             value: viewModel.streamSortOrderSelectedLabelKey,
                             image: .textLink,
                             bundle: .main,
                             action: { isShowingStreamSortOrderScreen = true }
                )

                SettingsCell(text: "settings.audio-selection.label",
                             textColor: .white,
                             value: viewModel.audioSelectedLabelKey,
                             image: .textLink,
                             bundle: .main,
                             action: { isShowingAudioSelectionScreen = true }
                )
            }
            .environment(\.defaultMinListRowHeight, Layout.spacing6x)
            .navigationBarBackButtonHidden()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(viewModel.settingsScreenTitle)
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

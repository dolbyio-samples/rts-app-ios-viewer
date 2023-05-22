//
//  SettingsScreen.swift
//

import SwiftUI
import DolbyIOUIKit

public struct SettingsScreen: View {

    @Environment(\.presentationMode) var presentationMode

    public let title: LocalizedStringKey
    @Binding public var isShowLabelsOn: Bool

    @State private var isShowingMultiviewScreen: Bool = false
    @State private var isShowingStreamSortorderScreen: Bool = false
    @State private var isShowingAudioSelectionScreen: Bool = false

    public enum Mode {
        case global
        case stream
    }

    public init(mode: Mode = .stream,
                isShowLableOn: Binding<Bool>) {
        switch mode {
        case .global: title = "settings.global.title.label"
        default: title = "settings.stream.title.label"
        }
        self._isShowLabelsOn = isShowLableOn
    }

    public var body: some View {
        ZStack(alignment: Alignment(horizontal: .center, vertical: .top)) {
            NavigationLink(
                destination: LazyNavigationDestinationView(SettingsMultiviewScreen()),
                isActive: $isShowingMultiviewScreen) {
                    EmptyView()
                }
                .hidden()

            NavigationLink(
                destination: LazyNavigationDestinationView(SettingsStreamSortorderScreen()),
                isActive: $isShowingStreamSortorderScreen) {
                    EmptyView()
                }
                .hidden()

            NavigationLink(
                destination: LazyNavigationDestinationView(SettingsAudioSelectionScreen()),
                isActive: $isShowingAudioSelectionScreen) {
                    EmptyView()
                }
                .hidden()

            List {
                Toggle("Show source labels", isOn: $isShowLabelsOn)

                SettingsCell(text: "settings.default-multiview-layout.label",
                             textColor: .white,
                             value: .constant("List view"),
                             valueColor: .gray,
                             image: .textLink,
                             bundle: .module,
                             action: { isShowingMultiviewScreen = true }
                )

                SettingsCell(text: "settings.stream-sort-order.label",
                             textColor: .white,
                             value: .constant("Connection order"),
                             image: .textLink,
                             bundle: .module,
                             action: { isShowingStreamSortorderScreen = true }
                )

                SettingsCell(text: "settings.audio-selection.label",
                             textColor: .white,
                             value: .constant("First source"),
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
            SettingsScreen(isShowLableOn: .constant(false))
        }
    }
}

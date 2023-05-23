//
//  SettingMultiviewScreen.swift
//

import SwiftUI
import DolbyIOUIKit

struct SettingsMultiviewScreen: View {
    @Environment(\.presentationMode) var presentationMode

    @State var settings: [SelectionsGroup.Item] = [
        .init(key: "default-multi-view-layout.list-view.label", bundle: .module, selected: true),
        .init(key: "default-multi-view-layout.grid-view.label", bundle: .module, selected: false),
        .init(key: "default-multi-view-layout.single-stream-view.label", bundle: .module, selected: false)
    ]

    var body: some View {
        SelectionsScreen(settings: $settings,
                         footer: "default-multi-view-layout.footer.label",
                         footerBundle: .module)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("default-multi-view-layout.title.label", bundle: .module)
            }
        }
    }
}

struct SettingsMultiviewScreen_Previews: PreviewProvider {
    static var previews: some View {
        SettingsMultiviewScreen()
    }
}

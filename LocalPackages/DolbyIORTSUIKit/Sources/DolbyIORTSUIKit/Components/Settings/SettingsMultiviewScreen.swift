//
//  SettingMultiviewScreen.swift
//

import SwiftUI
import DolbyIOUIKit

public struct SettingsMultiviewScreen: View {
    @Environment(\.presentationMode) var presentationMode

    let bundle: Bundle

    public init(bundle: Bundle? = nil) {
        self.bundle = bundle ?? .module
    }

    @State var settings: [SelectionsGroup.Item] = [
        .init(key: "default-multi-view-layout.list-view.label", bundle: .module, selected: true),
        .init(key: "default-multi-view-layout.grid-view.label", bundle: .module, selected: false),
        .init(key: "default-multi-view-layout.single-stream-view.label", bundle: .module, selected: false)
    ]

    public var body: some View {
        SelectionsScreen(settings: $settings,
                         footer: "default-multi-view-layout.footer.label",
                         footerBundle: bundle)
    }
}

struct SettingsMultiviewScreen_Previews: PreviewProvider {
    static var previews: some View {
        SettingsMultiviewScreen()
    }
}

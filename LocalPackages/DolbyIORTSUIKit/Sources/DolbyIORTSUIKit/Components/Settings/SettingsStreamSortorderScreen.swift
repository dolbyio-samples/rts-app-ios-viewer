//
//  SettingsStreamSortorderScreen.swift
//

import SwiftUI
import DolbyIOUIKit

struct SettingsStreamSortorderScreen: View {
    @Environment(\.presentationMode) var presentationMode

    @State var settings: [SelectionsGroup.Item] = [
        .init(key: "stream-sort-order.connection-order.label", bundle: .module, selected: true),
        .init(key: "stream-sort-order.alphanumeric.label", bundle: .module, selected: false)
    ]

    var body: some View {
        SelectionsScreen(settings: $settings,
                         footer: "stream-sort-order.footer.label",
                         footerBundle: .module)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("stream-sort-order.title.label", bundle: .module)
            }
        }
    }
}

struct SettingsStreamSortorderScreen_Previews: PreviewProvider {
    static var previews: some View {
        SettingsStreamSortorderScreen()
    }
}

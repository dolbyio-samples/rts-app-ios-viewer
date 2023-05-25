//
//  SettingsStreamSortorderScreen.swift
//

import SwiftUI
import DolbyIOUIKit
import DolbyIORTSCore

struct SettingsStreamSortorderScreen: View {

    @ObservedObject private var viewModel: StreamSettingsViewModel

    @State var settings: [SelectionsGroup.Item]

    let sortOrder: [StreamSettings.StreamSortOrder] = [.connectionOrder, .alphaNunmeric]

    init(_ viewModel: StreamSettingsViewModel) {
        self.viewModel = viewModel
        self.settings  = [
            .init(key: "stream-sort-order.connection-order.label",
                  bundle: .module,
                  selected: viewModel.streamSortOrder == .connectionOrder),
            .init(key: "stream-sort-order.alphanumeric.label",
                  bundle: .module,
                  selected: viewModel.streamSortOrder == .alphaNunmeric)
        ]
    }

    var body: some View {
        SelectionsScreen(settings: $settings,
                         footer: "stream-sort-order.footer.label",
                         footerBundle: .module,
                         onSelection: { viewModel.setStreamSortOrder(sortOrder[$0]) })
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("stream-sort-order.title.label", bundle: .module)
            }
        }
    }
}

struct SettingsStreamSortorderScreen_Previews: PreviewProvider {
    static var previews: some View {
        SettingsStreamSortorderScreen(.init(settings: StreamSettings()))
    }
}

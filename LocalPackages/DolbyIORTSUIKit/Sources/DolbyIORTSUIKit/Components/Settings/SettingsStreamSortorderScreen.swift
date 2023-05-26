//
//  SettingsStreamSortorderScreen.swift
//

import SwiftUI
import DolbyIOUIKit

struct SettingsStreamSortorderScreen: View {

    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        SelectionsScreen(settings: viewModel.streamSortOrderSelectionItems,
                         footer: "stream-sort-order.footer.label",
                         footerBundle: .module,
                         onSelection: { viewModel.selectStreamSortOrder(with: $0) })
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("stream-sort-order.title.label", bundle: .module)
            }
        }
    }
}

struct SettingsStreamSortorderScreen_Previews: PreviewProvider {
    static var previews: some View {
        SettingsStreamSortorderScreen(viewModel: .init())
    }
}

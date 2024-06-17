//
//  SettingsStreamSortorderScreen.swift
//

import SwiftUI
import DolbyIOUIKit

struct SettingsStreamSortOrderScreen: View {

    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        SelectionsScreen(settings: viewModel.streamSortOrderSelectionItems,
                         footer: "stream-sort-order.footer.label",
                         footerBundle: .main,
                         onSelection: { viewModel.selectStreamSortOrder(with: $0) }, screenName: "StreamSortOrderScreen")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("stream-sort-order.title.label")
            }
        }
    }
}

struct SettingsStreamSortorderScreen_Previews: PreviewProvider {
    static var previews: some View {
        SettingsStreamSortOrderScreen(viewModel: .init(mode: .global))
    }
}

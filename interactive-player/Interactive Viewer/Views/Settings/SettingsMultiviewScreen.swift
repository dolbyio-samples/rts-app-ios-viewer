//
//  SettingMultiviewScreen.swift
//

import SwiftUI
import DolbyIOUIKit

struct SettingsMultiviewScreen: View {

    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        SelectionsScreen(settings: viewModel.multiviewSelectionItems,
                         footer: "default-multi-view-layout.footer.label",
                         footerBundle: .main,
                         onSelection: { viewModel.selectMultiviewLayout(with: $0) }, screenName: "MultiViewScreen")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("default-multi-view-layout.title.label")
            }
        }
    }
}

struct SettingsMultiviewScreen_Previews: PreviewProvider {
    static var previews: some View {
        SettingsMultiviewScreen(viewModel: .init(mode: .global))
    }
}

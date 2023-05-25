//
//  SettingMultiviewScreen.swift
//

import SwiftUI
import DolbyIOUIKit
import DolbyIORTSCore

struct SettingsMultiviewScreen: View {

    @ObservedObject private var viewModel: StreamSettingsViewModel

    @State var settings: [SelectionsGroup.Item]
    let multiviews: [StreamSettings.MultiviewLayout] = [.list, .grid, .single]

    init(_ viewModel: StreamSettingsViewModel) {
        self.viewModel = viewModel
        self.settings = [
            .init(key: "default-multi-view-layout.list-view.label",
                  bundle: .module,
                  selected: viewModel.multiviewLayout == .list),
            .init(key: "default-multi-view-layout.grid-view.label",
                  bundle: .module,
                  selected: viewModel.multiviewLayout == .grid),
            .init(key: "default-multi-view-layout.single-stream-view.label",
                  bundle: .module,
                  selected: viewModel.multiviewLayout == .single)
        ]
    }

    var body: some View {
        SelectionsScreen(settings: $settings,
                         footer: "default-multi-view-layout.footer.label",
                         footerBundle: .module,
                         onSelection: {
            let view = multiviews[$0]
            viewModel.setMultiviewLayout(view)
        })
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("default-multi-view-layout.title.label", bundle: .module)
            }
        }
    }
}

struct SettingsMultiviewScreen_Previews: PreviewProvider {
    static var previews: some View {
        SettingsMultiviewScreen(.init(settings: StreamSettings()))
    }
}

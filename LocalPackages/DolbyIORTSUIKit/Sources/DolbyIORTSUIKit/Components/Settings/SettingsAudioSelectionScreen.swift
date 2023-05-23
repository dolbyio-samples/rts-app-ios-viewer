//
//  SettingsAudioSelectionScreen.swift
//

import SwiftUI
import DolbyIOUIKit

struct SettingsAudioSelectionScreen: View {

    @State var globalAudioSelections: [SelectionsGroup.Item] = [
        .init(key: "audio-selection.first-source.label", bundle: .module, selected: true),
        .init(key: "audio-selection.main-source.label", bundle: .module, selected: false)]

    var body: some View {
        SelectionsScreen(settings: $globalAudioSelections,
                         footer: "audio-selection.global.footer.label",
                         footerBundle: .module)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("audio-selection.title.label", bundle: .module)
            }
        }
    }
}

struct SettingsAudioSelectionScreen_Previews: PreviewProvider {
    static var previews: some View {
        SettingsAudioSelectionScreen()
    }
}

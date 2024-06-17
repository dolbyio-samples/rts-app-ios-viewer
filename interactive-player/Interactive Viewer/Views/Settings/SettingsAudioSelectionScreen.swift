//
//  SettingsAudioSelectionScreen.swift
//

import SwiftUI
import DolbyIOUIKit

struct SettingsAudioSelectionScreen: View {

    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        SelectionsScreen(settings: viewModel.audioSelectionsItems,
                         footer: "audio-selection.global.footer.label",
                         footerBundle: .main,
                         onSelection: { viewModel.selectAudioSelection(with: $0) }, screenName: "AudioSelectionScreen")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("audio-selection.title.label")
            }
        }
    }
}

struct SettingsAudioSelectionScreen_Previews: PreviewProvider {
    static var previews: some View {
        SettingsAudioSelectionScreen(viewModel: .init(mode: .global))
    }
}

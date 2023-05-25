//
//  SettingsAudioSelectionScreen.swift
//

import SwiftUI
import DolbyIOUIKit
import DolbyIORTSCore

struct SettingsAudioSelectionScreen: View {

    @ObservedObject private var viewModel: StreamSettingsViewModel

    @State var globalAudioSelections: [SelectionsGroup.Item]

    let audioSelection: [StreamSettings.AudioSelection] = [.firstSource, .mainSource]

    init(_ viewModel: StreamSettingsViewModel) {
        self.viewModel = viewModel
        globalAudioSelections = [
            .init(key: "audio-selection.first-source.label",
                  bundle: .module,
                  selected: viewModel.audioSelection == .firstSource),
            .init(key: "audio-selection.main-source.label",
                  bundle: .module,
                  selected: viewModel.audioSelection == .mainSource)]
    }

    var body: some View {
        SelectionsScreen(settings: $globalAudioSelections,
                         footer: "audio-selection.global.footer.label",
                         footerBundle: .module,
                         onSelection: {
            let audio = audioSelection[$0]
            viewModel.setAudioSelection(audio)
        })
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("audio-selection.title.label", bundle: .module)
            }
        }
    }
}

struct SettingsAudioSelectionScreen_Previews: PreviewProvider {
    static var previews: some View {
        SettingsAudioSelectionScreen(.init(settings: StreamSettings()))
    }
}

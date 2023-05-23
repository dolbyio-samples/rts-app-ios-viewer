//
//  StreamingView.swift
//

import SwiftUI
import DolbyIORTSCore

public struct StreamingView: View {
    @StateObject private var viewModel: StreamViewModel = .init()

    public init() {}

    public var body: some View {
        switch viewModel.mode {
        case .list, .single:
            ListView(
                viewModel: viewModel,
                selectedAudioIndex: viewModel.audioSelectedIndex,
                selectedVideoIndex: viewModel.videoSelectedIndex,
                onSelectVideoSource: { index in viewModel.videoSelectedChange(index: index) },
                onChangeOfViewMode: { viewModel.selectedSourceClick() })
        }
    }
}

struct StreamingView_Previews: PreviewProvider {
    static var previews: some View {
        StreamingView()
    }
}

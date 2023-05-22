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
            ListView(viewModel: viewModel, highlighted: viewModel.highlighted, onHighlightedChange: { index in viewModel.highlightedChange(index: index) }, onHighlightedClick: { viewModel.highlightedClick() })
        }
    }
}

struct StreamingView_Previews: PreviewProvider {
    static var previews: some View {
        StreamingView()
    }
}

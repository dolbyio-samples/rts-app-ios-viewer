//
//  StreamingView.swift
//

import SwiftUI
import DolbyIORTSCore

public struct StreamingView: View {
    @StateObject private var viewModel: StreamViewModel = .init()

    @State private var highlighted: Int = 0

    public init() {}

    public var body: some View {
        ListView(viewModel: viewModel, highlighted: highlighted, onHighlighted: { index in highlighted = index })
    }
}

struct StreamingView_Previews: PreviewProvider {
    static var previews: some View {
        StreamingView()
    }
}

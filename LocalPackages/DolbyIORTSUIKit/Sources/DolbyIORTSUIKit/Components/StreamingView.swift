//
//  StreamingView.swift
//

import SwiftUI
import DolbyIORTSCore

public struct StreamingView: View {
    @StateObject private var viewModel: StreamViewModel = .init()

    public init() {}

    public var body: some View {
        EmptyView()
    }
}

struct StreamingView_Previews: PreviewProvider {
    static var previews: some View {
        StreamingView()
    }
}

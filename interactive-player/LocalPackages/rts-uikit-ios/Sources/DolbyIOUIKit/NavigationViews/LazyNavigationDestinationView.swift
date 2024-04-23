//
//  LazyNavigationDestinationView.swift
//

import SwiftUI

public struct LazyNavigationDestinationView<Content: View>: View {
    private let build: () -> Content

    public init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }

    public var body: Content {
        build()
    }
}

#if DEBUG
struct LazyNavigationDestinationView_Previews: PreviewProvider {
    static var previews: some View {
        LazyNavigationDestinationView(SwiftUI.Text("Hello world"))
    }
}
#endif

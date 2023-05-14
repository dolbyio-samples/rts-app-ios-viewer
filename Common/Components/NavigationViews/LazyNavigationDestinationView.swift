//
//  LazyNavigationDestinationView.swift
//

import SwiftUI

struct LazyNavigationDestinationView<Content: View>: View {
    private let build: () -> Content

    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }

    var body: Content {
        build()
    }
}

#if DEBUG
struct LazyNavigationDestinationView_Previews: PreviewProvider {
    static var previews: some View {
        LazyNavigationDestinationView(Text("Hello world"))
    }
}
#endif

//
//  ViewSizePreferenceKey.swift
//

import SwiftUI

struct ViewSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

extension View {
    public func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(key: ViewSizePreferenceKey.self, value: geometryProxy.size)
            }
        )
        .onPreferenceChange(ViewSizePreferenceKey.self, perform: onChange)
    }
}

//
//  IconView.swift
//  

import SwiftUI

public struct IconView: View {
    private let name: ImageAsset
    private let tintColor: Color?
    private let theme: Theme = ThemeManager.shared.theme

    public init(name: ImageAsset, tintColor: Color? = nil) {
        self.name = name
        self.tintColor = tintColor
    }

    public var body: some View {
        theme[name]
            .renderingMode(.template)
            .foregroundColor(_tintColor)
            .fixedSize()
    }

    private var _tintColor: Color? {
        tintColor ?? theme[.icon(.tintColor)]
    }
}

#if DEBUG
struct IconView_Previews: PreviewProvider {
    static var previews: some View {
        IconView(name: .success, tintColor: .red)
    }
}
#endif

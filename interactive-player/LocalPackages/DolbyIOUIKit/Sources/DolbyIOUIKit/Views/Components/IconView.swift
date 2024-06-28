//
//  IconView.swift
//  

import SwiftUI

public struct IconView: View {
    private let iconAsset: IconAsset
    private let tintColor: Color?
    @ObservedObject private var themeManager = ThemeManager.shared

    public init(iconAsset: IconAsset, tintColor: Color? = nil) {
        self.iconAsset = iconAsset
        self.tintColor = tintColor
    }

    private var attribute: IconAttribute {
        themeManager.theme.iconAttribute()
    }

    public var body: some View {
        Image(iconAsset.rawValue, bundle: Bundle.module)
            .renderingMode(.template)
            .foregroundColor(_tintColor)
            .fixedSize()
    }

    private var _tintColor: Color? {
        tintColor ?? attribute.tintColor
    }
}

#if DEBUG
struct IconView_Previews: PreviewProvider {
    static var previews: some View {
        IconView(iconAsset: .success, tintColor: .red)
    }
}
#endif

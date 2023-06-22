//
//  NavigationHeaderView.swift
//  

import SwiftUI
import DolbyIOUIKit

extension View {
    func navigationHeaderView() -> some View {
        self.safeAreaInset(edge: .top) {
            NavigationHeaderView()
        }
#if os(tvOS)
        .ignoresSafeArea()
#endif
    }
}

struct NavigationHeaderView: View, ShapeStyle {

    @ObservedObject private var themeManager = ThemeManager.instance

    var body: some View {
        ZStack {
            IconView(iconAsset: .dolby_logo_dd, tintColor: .white)
        }
        .frame(maxWidth: .infinity, maxHeight: Layout.spacing9x)
        .background(
            Color(uiColor: themeManager.theme.background)
        )
    }
}

#if DEBUG
struct NavigationHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationHeaderView()
    }
}
#endif

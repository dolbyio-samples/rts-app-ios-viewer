//
//  NavigationHeaderView.swift
//  

import SwiftUI
import DolbyIOUIKit

public extension View {
    func navigationHeaderView() -> some View {
        self.safeAreaInset(edge: .top) {
            NavigationHeaderView()
        }
        .ignoresSafeArea()
    }
}

public struct NavigationHeaderView: View, ShapeStyle {

    public init() {}

    public var body: some View {
            ZStack {
                IconView(name: .dolby_logo_dd, tintColor: .white)
            }
            .frame(maxWidth: .infinity, maxHeight: Layout.spacing9x)
            .background(
                Color(uiColor: UIColor.Background.black)
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

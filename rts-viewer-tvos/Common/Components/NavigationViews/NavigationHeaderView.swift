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

struct NavigationHeaderView: View {

    var body: some View {
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

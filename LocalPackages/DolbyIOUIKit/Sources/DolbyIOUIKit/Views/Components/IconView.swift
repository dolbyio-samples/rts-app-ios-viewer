//
//  SwiftUIView.swift
//  
//
//  Created by Raveendran, Aravind on 6/1/2023.
//

import SwiftUI

public struct IconView: View {
    public var name: ImageAsset
    public var tintColor: Color?
    private var theme: Theme = ThemeManager.shared.theme
    
    public init(name: ImageAsset, tintColor: Color? = nil) {
        self.name = name
        self.tintColor = tintColor
    }

    public var body: some View {
        theme[name]
            .renderingMode(.template)
            .foregroundColor(tintColor)
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

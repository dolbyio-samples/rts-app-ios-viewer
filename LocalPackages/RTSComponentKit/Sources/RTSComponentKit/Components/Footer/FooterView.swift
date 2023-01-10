//
//  FooterView.swift
//  

import SwiftUI
import DolbyIOUIKit

public struct FooterView: View {
    public var text: LocalizedStringKey
    
    public init(text: LocalizedStringKey) {
        self.text = text
    }
    
    public var body: some View {
        DolbyIOUIKit.Text(
            text: text,
            font: .avenirNextRegular(
                withStyle: .footnote,
                size: FontSize.footnote
            )
        )
    }
}

#if DEBUG
struct FooterView_Previews: PreviewProvider {
    static var previews: some View {
        FooterView(text: "Copyright © 2022 Dolby.io — All Rights Reserved")
    }
}
#endif

//
//  FooterView.swift
//  

import SwiftUI
import DolbyIOUIKit

struct FooterView: View {
    var text: LocalizedStringKey

    init(text: LocalizedStringKey) {
        self.text = text
    }

    var body: some View {
        DolbyIOUIKit.Text(
            text: text,
            font: .avenirNextRegular(
                withStyle: .caption,
                size: FontSize.caption1
            )
        )
    }
}

#if DEBUG
struct FooterView_Previews: PreviewProvider {
    static var previews: some View {
        FooterView(text: "Copyright © 2025 Dolby OptiView — All Rights Reserved")
    }
}
#endif

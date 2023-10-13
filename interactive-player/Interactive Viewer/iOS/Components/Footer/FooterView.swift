//
//  FooterView.swift
//  

import SwiftUI
import DolbyIOUIKit

struct FooterView: View {
    private let text: LocalizedStringKey

    init(text: LocalizedStringKey) {
        self.text = text
    }

    var body: some View {
        DolbyIOUIKit.Text(
            text,
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
        FooterView(text: "Copyright © 2022 Dolby.io — All Rights Reserved")
    }
}
#endif

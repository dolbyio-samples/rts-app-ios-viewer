//
//  SourceLabel.swift
//

import SwiftUI
import DolbyIOUIKit

struct SourceLabel: View {

    let sourceId: String

    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        SwiftUI.Text(sourceId)
            .foregroundColor(.white)
            .font(.custom("AvenirNext-Regular", size: FontSize.caption1, relativeTo: .caption))
            .padding(.horizontal, Layout.spacing1x)
            .background(Color(uiColor: themeManager.theme.neutral400))
            .cornerRadius(Layout.cornerRadius4x)
    }
}

struct SourceLabel_Previews: PreviewProvider {
    static var previews: some View {
        SourceLabel(sourceId: "Camera 01")
    }
}

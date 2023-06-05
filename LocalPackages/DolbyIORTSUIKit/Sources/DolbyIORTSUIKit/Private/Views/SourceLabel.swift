//
//  SourceLabel.swift
//

import SwiftUI
import DolbyIOUIKit

struct SourceLabel: View {

    let sourceId: String

    var body: some View {
        SwiftUI.Text(sourceId)
            .foregroundColor(.white)
            .font(.avenirNextRegular(withStyle: .body, size: FontSize.caption1))
            .padding(.horizontal, Layout.spacing1x)
            .background(Color(uiColor: UIColor.Neutral.neutral400))
            .cornerRadius(Layout.cornerRadius4x)
    }
}

struct SourceLabel_Previews: PreviewProvider {
    static var previews: some View {
        SourceLabel(sourceId: "Camera 01")
    }
}

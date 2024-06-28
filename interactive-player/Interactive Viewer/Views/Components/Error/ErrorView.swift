//
//  ErrorView.swift
//

import DolbyIOUIKit
import SwiftUI

struct ErrorView: View {
    let title: String
    let subtitle: String?

    init(title: String, subtitle: String?) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack {
            Text(
                verbatim: title,
                font: .custom("AvenirNext-Regular", size: FontSize.title2, relativeTo: .title2)
            )
            .multilineTextAlignment(.center)
            if let subtitle = subtitle {
                Text(
                    verbatim: subtitle,
                    font: .custom("AvenirNext-Regular", size: FontSize.subhead, relativeTo: .subheadline)
                )
                .multilineTextAlignment(.center)
            }
        }
    }
}

struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorView(title: .noInternetErrorTitle, subtitle: nil)
    }
}

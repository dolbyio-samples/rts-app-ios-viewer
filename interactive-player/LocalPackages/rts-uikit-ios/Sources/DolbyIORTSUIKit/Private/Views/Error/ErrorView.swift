//
//  ErrorView.swift
//

import DolbyIOUIKit
import SwiftUI

struct ErrorView: View {
    let viewModel: ErrorViewModel

    init(viewModel: ErrorViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text(
                verbatim: viewModel.titleText,
                font: .custom("AvenirNext-Regular", size: FontSize.title2, relativeTo: .title2)
            )
            .multilineTextAlignment(.center)
            if let subtitleText = viewModel.subtitleText {
                Text(
                    verbatim: subtitleText,
                    font: .custom("AvenirNext-Regular", size: FontSize.subhead, relativeTo: .subheadline)
                )
                .multilineTextAlignment(.center)
            }
        }
    }
}

struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorView(viewModel: .streamOffline)
    }
}

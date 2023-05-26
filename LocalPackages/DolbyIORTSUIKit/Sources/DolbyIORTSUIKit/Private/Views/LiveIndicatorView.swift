//
//  LiveIndicatorView.swift
//

import DolbyIOUIKit
import SwiftUI

struct LiveIndicatorView: View {

    @StateObject private var viewModel: LiveIndicatorViewModel = .init()

    var body: some View {
        Text(text: viewModel.isStreamActive ? "stream.live.label" : "stream.offline.label",
             fontAsset: .avenirNextBold(
                size: FontSize.caption2,
                style: .caption2
             )
        )
        .padding(.horizontal, Layout.spacing2x)
        .padding(.vertical, Layout.spacing1x)
        .background(
            viewModel.isStreamActive ?
            Color(uiColor: UIColor.Feedback.error500) :
                Color(uiColor: UIColor.Neutral.neutral400)
        )
        .cornerRadius(Layout.cornerRadius6x)
    }
}

struct LiveIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        LiveIndicatorView()
    }
}

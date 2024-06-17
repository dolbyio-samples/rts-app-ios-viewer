//
//  LiveIndicatorView.swift
//

import DolbyIOUIKit
import SwiftUI

struct LiveIndicatorView: View {

    private let viewModel: LiveIndicatorViewModel
    @ObservedObject private var themeManager = ThemeManager.shared

    private var theme: Theme {
        themeManager.theme
    }

    init(isStreamActive: Bool) {
        self.viewModel = LiveIndicatorViewModel(isStreamActive: isStreamActive)
        self.themeManager = themeManager
    }

    var body: some View {
        Text(
            viewModel.isStreamActive ? "stream.live.label" : "stream.offline.label",
            bundle: .main,
            font: .custom("AvenirNext-Bold", size: FontSize.caption2, relativeTo: .caption2)
        )
        .padding(.horizontal, Layout.spacing2x)
        .padding(.vertical, Layout.spacing1x)
        .background(
            viewModel.isStreamActive ?
            Color(uiColor: theme.error500) :
                Color(uiColor: theme.neutral400)
        )
        .cornerRadius(Layout.cornerRadius6x)
    }
}

struct LiveIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        LiveIndicatorView(isStreamActive: true)
    }
}

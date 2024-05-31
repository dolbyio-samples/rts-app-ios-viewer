//
//  LiveIndicatorView.swift
//

import SwiftUI
import DolbyIOUIKit

struct LiveIndicatorView: View {
    let isStreamLive: Bool
    var body: some View {
        Text(text: isStreamLive ? "stream.live.label" : "stream.offline.label",
             fontAsset: .avenirNextBold(
                size: FontSize.caption2,
                style: .caption2
             )
        )
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
        .background(
            isStreamLive ? Color(uiColor: UIColor.Feedback.error500) : Color(uiColor: UIColor.Neutral.neutral400)
        )
        .cornerRadius(Layout.cornerRadius6x)
    }
}

#Preview {
    LiveIndicatorView(isStreamLive: true)
}

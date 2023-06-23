//
//  StreamConnectionView.swift
//

import DolbyIOUIKit
import Foundation
import SwiftUI

struct StreamConnectionView: View {
    let isNetworkConnected: Bool

    init(isNetworkConnected: Bool) {
        self.isNetworkConnected = isNetworkConnected
    }

    var body: some View {
        if isNetworkConnected {
            VStack {
                Text(
                    text: "stream.offline.title.label",
                    fontAsset: .avenirNextDemiBold(
                        size: FontSize.title3,
                        style: .title3
                    )
                )
                Text(
                    text: "stream.offline.subtitle.label",
                    fontAsset: .avenirNextRegular(
                        size: FontSize.caption2,
                        style: .caption2
                    )
                )
            }
        } else {
            Text(
                text: "stream.network.disconnected.label",
                fontAsset: .avenirNextDemiBold(
                    size: FontSize.title3,
                    style: .title3
                )
            )
        }
    }
}

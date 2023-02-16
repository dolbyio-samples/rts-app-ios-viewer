//
//  StreamConnectionView.swift
//

import DolbyIOUIKit
import Foundation
import SwiftUI
import RTSComponentKit
import Network

struct StreamConnectionView: View {
    let isStreamActive: Bool
    let isNetworkConnected: Bool

    init(isStreamActive: Bool, isNetworkConnected: Bool) {
        self.isStreamActive = isStreamActive
        self.isNetworkConnected = isNetworkConnected
    }

    var body: some View {
        ZStack {
            if !isStreamActive {
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
    }
}

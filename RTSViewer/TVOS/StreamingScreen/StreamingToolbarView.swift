//
//  StreamingTopToolbar.swift
//

import DolbyIOUIKit
import Foundation
import SwiftUI
import RTSComponentKit

struct StreamingToolbarView: View {
    @ObservedObject private var viewModel: StreamToolbarViewModel

    @Binding var showSettings: Bool
    @Binding var showToolbar: Bool

    @Environment(\.dismiss) var dismiss

    init(viewModel: StreamToolbarViewModel, showSettings: Binding<Bool>, showToolbar: Binding<Bool>) {
        self.viewModel = viewModel

        _showSettings = showSettings
        _showToolbar = showToolbar
    }

    var body: some View {

        VStack {
            if viewModel.isLiveIndicatorEnabled {
                HStack {
                    Text(text: viewModel.isStreamActive ? "stream.live.label" : "stream.offline.label",
                         fontAsset: .avenirNextBold(
                            size: FontSize.caption2,
                            style: .caption2
                         )
                    ).padding(.leading, 20)
                        .padding(.trailing, 20)
                        .padding(.top, 6)
                        .padding(.bottom, 6)
                        .background(viewModel.isStreamActive ? Color(uiColor: UIColor.Feedback.error500) : Color(uiColor: UIColor.Neutral.neutral400))
                        .cornerRadius(Layout.cornerRadius6x)
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
        }.frame(maxHeight: .infinity, alignment: .top)
            .padding(.leading, 56)
            .padding(.top, 37)

        if viewModel.isStreamActive {
            if showToolbar {
                VStack {
                    HStack {
                        IconButton(
                            text: "stream.settings.button",
                            name: .settings
                        ) {
                            withAnimation {
                                showSettings = !showSettings
                            }
                        }
                        Spacer().frame(width: Layout.spacing1x)
                    }.frame(maxWidth: .infinity, alignment: .trailing)
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding()
                .transition(.move(edge: .bottom))
            }
        }

        if !showToolbar {
            AnyGestureRecognizer(triggered: $showToolbar)
        }
    }
}

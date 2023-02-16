//
//  StreamingToolbarView.swift
//

import DolbyIOUIKit
import Foundation
import SwiftUI
import RTSComponentKit

struct StreamingToolbarView: View {
    @ObservedObject private var viewModel: StreamToolbarViewModel

    @Binding var showSettings: Bool
    @Binding var showToolbar: Bool
    @Binding var showStats: Bool

    let showSimulcast: Bool
    @Environment(\.dismiss) var dismiss

    init(viewModel: StreamToolbarViewModel, showSimulcast: Bool, showSettings: Binding<Bool>, showToolbar: Binding<Bool>, showStats: Binding<Bool>) {
        self.viewModel = viewModel
        self.showSimulcast = showSimulcast

        _showSettings = showSettings
        _showToolbar = showToolbar
        _showStats = showStats
    }

    var body: some View {
        ZStack {
            ZStack {
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
                        Text(viewModel.streamName ?? "")
                        if viewModel.isLiveIndicatorEnabled {
                            HStack {
                                IconButton(
                                    name: .close
                                ) {
                                    dismiss()
                                }
                                .background(.gray)
                                .clipShape(Circle())
                                Spacer().frame(width: Layout.spacing1x)
                            }.frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
            }.frame(maxHeight: .infinity, alignment: .top)
                .padding(.leading, 16)
                .padding(.top, 27)
            if viewModel.isStreamActive {
                HStack {
                    HStack {
                        SwiftUI.Button(action: {
                            withAnimation {
                                showStats = !showStats
                            }
                        }) {
                            IconView(name: .info)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    if showSimulcast {
                        HStack {
                            SwiftUI.Button(action: {
                                withAnimation {
                                    showSettings = !showSettings
                                }
                            }) {
                                IconView(name: .more)
                            }
                            Spacer().frame(width: Layout.spacing1x)
                        }.frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding()
                .transition(.move(edge: .bottom))
            }
        }
    }
}

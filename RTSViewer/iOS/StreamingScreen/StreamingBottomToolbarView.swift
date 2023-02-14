//
//  StreamingBottomToolbarView.swift
//

import DolbyIOUIKit
import Foundation
import SwiftUI
import RTSComponentKit

struct StreamingBottomToolbarView: View {
    @ObservedObject private var viewModel: StreamToolbarViewModel

    @Binding var showSettings: Bool
    @Binding var showToolbar: Bool
    @Binding var showStats: Bool

    let showSimulcast: Bool

    init(viewModel: StreamToolbarViewModel, showSimulcast: Bool, showSettings: Binding<Bool>, showToolbar: Binding<Bool>, showStats: Binding<Bool>) {
        self.viewModel = viewModel
        self.showSimulcast = showSimulcast

        _showSettings = showSettings
        _showToolbar = showToolbar
        _showStats = showStats
    }

    var body: some View {
        if viewModel.isStreamActive {
            HStack {
                HStack {
                    IconButton(
                        name: .info
                    ) {
                        withAnimation {
                            showStats = !showStats
                        }
                    }
                    Spacer().frame(width: Layout.spacing1x)
                }.frame(maxWidth: .infinity, alignment: .leading)
                if showSimulcast {
                    HStack {
                        IconButton(
                            name: .more
                        ) {
                            withAnimation {
                                showSettings = !showSettings
                            }
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

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

    init(viewModel: StreamToolbarViewModel, _: Bool, showSettings: Binding<Bool>, showToolbar: Binding<Bool>, _: Binding<Bool>) {
        self.viewModel = viewModel

        _showSettings = showSettings
        _showToolbar = showToolbar
    }

    var body: some View {
        if viewModel.isStreamActive {
            if showToolbar {
                VStack {
                    HStack {
                        IconButton(
                            text: "stream.settings.button",
                            name: .settings
                        ) {
                            withAnimation {
                                showSettings = true
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

//
//  LandingView.swift
//

import RTSComponentKit
import SwiftUI

struct LandingView: View {
    @StateObject private var viewModel: LandingViewModel = .init()
    @State private var isShowingStreamInputView = false
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            if viewModel.hasSavedStreams {
                RecentStreamsScreen()
            } else {
                StreamDetailInputScreen()
            }
        }
        .layoutPriority(1)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .id(appState.rootViewID)
        .onAppear {
            viewModel.startStreamObservations()
        }
        .onDisappear {
            viewModel.stopStreamObservations()
        }
    }
}

struct LandingView_Previews: PreviewProvider {
    static var previews: some View {
        LandingView()
    }
}

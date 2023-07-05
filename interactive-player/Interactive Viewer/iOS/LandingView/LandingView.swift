//
//  LandingView.swift
//

import SwiftUI

struct LandingView: View {
    @StateObject private var viewModel: LandingViewModel = .init()
    @State private var isShowingStreamInputView = false
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            RecentStreamsScreen()
                .opacity(viewModel.hasSavedStreams ? 1 : 0)
            StreamDetailInputScreen()
                .opacity(viewModel.hasSavedStreams ? 0 : 1)
        }
        .layoutPriority(1)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .id(appState.rootViewID)
        .onAppear {
            viewModel.startStreamObservations()
        }
    }
}

struct LandingView_Previews: PreviewProvider {
    static var previews: some View {
        LandingView()
    }
}

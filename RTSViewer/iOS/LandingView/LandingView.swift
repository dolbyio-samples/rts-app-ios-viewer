//
//  LandingView.swift
//

import RTSComponentKit
import SwiftUI

struct LandingView: View {
    @StateObject private var viewModel: LandingViewModel = .init()
    @State private var isShowingStreamInputView = false

    var body: some View {
        ZStack {
            if viewModel.hasSavedStreams {
                RecentStreamsScreen()
            } else {
                StreamDetailInputScreen()
            }
        }
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

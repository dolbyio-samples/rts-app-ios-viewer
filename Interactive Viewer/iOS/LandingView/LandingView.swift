//
//  LandingView.swift
//

import SwiftUI
import DolbyIORTSUIKit

struct LandingView: View {

    @StateObject private var viewModel: LandingViewModel = .init()
    @StateObject private var globalSettingsViewModel: StreamSettingsViewModel = .init()
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            if viewModel.hasSavedStreams {
                RecentStreamsScreen(globalSettingsViewModel)
            } else {
                StreamDetailInputScreen(globalSettingsViewModel)
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

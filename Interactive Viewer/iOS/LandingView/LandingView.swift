//
//  LandingView.swift
//

import SwiftUI
import DolbyIORTSCore
import DolbyIORTSUIKit

struct LandingView: View {

    @StateObject private var viewModel: LandingViewModel = .init()
    @StateObject private var globalSettingsViewModel: StreamSettingsViewModel = .init(settings: GlobalStreamSettings())
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
        .environmentObject(globalSettingsViewModel)
    }
}

struct LandingView_Previews: PreviewProvider {
    static var previews: some View {
        LandingView()
    }
}

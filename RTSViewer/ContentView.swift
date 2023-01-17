//
//  ContentView.swift
//  Millicast SDK Sample App in Swift
//

import SwiftUI
import RTSComponentKit

struct ContentView: View {

    var body: some View {
        NavigationView {
            StreamDetailInputScreen()
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .preferredColorScheme(.dark)
        .environmentObject(RTSDataStore())
        .task {
            RTSComponentKit.NetworkMonitor.shared.startMonitoring()
        }
    }
}

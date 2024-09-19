//
//  ContentView.swift
//  Millicast SDK Sample App in Swift
//

import SwiftUI

struct ContentView: View {

    var body: some View {
        NavigationView {
            LandingView()
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

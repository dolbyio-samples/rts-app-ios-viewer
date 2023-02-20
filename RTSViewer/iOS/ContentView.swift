//
//  ContentView.swift
//

import DolbyIOUIKit
import SwiftUI

struct ContentView: View {

    init() {
        let appearance = UINavigationBarAppearance()
        appearance.shadowColor = UIColor.Neutral.neutral700
        appearance.backgroundColor = UIColor.Neutral.neutral900
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        NavigationView {
            LandingView()
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

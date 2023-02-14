//
//  ContentView.swift
//

import SwiftUI

struct ContentView: View {

    var body: some View {
        NavigationView {
            StreamDetailInputScreen()
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

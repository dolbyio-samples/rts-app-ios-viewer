//
//  LoadingView.swift
//  

import SwiftUI

public struct LoadingView: View {

    @State private var spin: Bool = false
    var tintColor: Color?

    public init(tintColor: Color?) {
        self.tintColor = tintColor
    }

    public var body: some View {
        IconView(name: .loader, tintColor: tintColor)
            .fixedSize()
            .rotationEffect(.degrees(spin ? 360: 0))
            .foregroundColor(tintColor)
            .animation(
                .linear(duration: 0.8)
                .repeatForever(autoreverses: false),
                value: spin)
            .onAppear {
                spin = true
            }
            .onDisappear { spin = false }
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView(tintColor: .red)
    }
}

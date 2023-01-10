//
//  BackgroundContainerView.swift
//  

import SwiftUI

public struct BackgroundContainerView<Content: View>: View {
    private var content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        ZStack {
            Image(ImageAsset.background, bundle: .module)
                .resizable()
                .ignoresSafeArea()
            content()
        }
    }
}

#if DEBUG
struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        BackgroundContainerView {
            Text("Contents of the screen")
        }
    }
}
#endif

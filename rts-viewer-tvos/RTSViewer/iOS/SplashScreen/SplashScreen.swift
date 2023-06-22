//
//  SplashScreen.swift
//

import DolbyIOUIKit
import SwiftUI

struct SplashScreen: View {

    @State private var isActive = false

    var body: some View {
        ZStack {
            if isActive {
                ContentView()
            } else {
                Image("LaunchIcon")
                    .fixedSize()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation { isActive = true }
            }
        }
    }
}

#if DEBUG
struct SplashScreen_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreen()
    }
}
#endif

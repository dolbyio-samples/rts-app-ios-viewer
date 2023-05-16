//
//  StreamingScreen.swift
//

import DolbyIOUIKit
import DolbyIORTSCore
import DolbyIORTSUIKit
import SwiftUI
import Network

struct StreamingScreen: View {
    var body: some View {
        ZStack {
            StreamingView()
                .onDisappear {
                    Task {
                        await StreamCoordinator.shared.stopSubscribe()
                    }
                }

        }
    }
}

#if DEBUG
struct StreamingScreen_Previews: PreviewProvider {
    static var previews: some View {
        StreamingScreen()
    }
}
#endif

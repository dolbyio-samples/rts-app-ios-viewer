//
//  VideoView.swift
//

import DolbyIOUIKit
import Foundation
import SwiftUI
import RTSComponentKit
import MillicastSDK

struct VideoView: View {
    @ObservedObject private var viewModel: DisplayStreamViewModel

    init(viewModel: DisplayStreamViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        GeometryReader { geometry in
            if let videoTrack = viewModel.dataStore.mainVideoTrack {
                MCVideoSwiftUIView(videoTrack: videoTrack, scalingMode: .aspectFit, rendererType: .openGL)
                    .onAppear {
                        viewModel.updateScreenSize(width: Float(geometry.size.width), height: Float(geometry.size.height))
                    }
                    .frame(width: viewModel.width, height: viewModel.height)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }
}

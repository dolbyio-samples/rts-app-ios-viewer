//
//  VideoView.swift
//

import DolbyIOUIKit
import Foundation
import SwiftUI
import RTSComponentKit
import MillicastSDK

struct VideoView: View {

    let videoTrack: MCRTSRemoteVideoTrack

    var body: some View {
        GeometryReader { geometry in
            MCVideoSwiftUIView(rtsRemoteVideoTrack: videoTrack, scalingMode: .aspectFit, rendererType: .sampleBuffer)
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

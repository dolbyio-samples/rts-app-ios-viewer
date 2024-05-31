//
//  VideoView.swift
//

import DolbyIOUIKit
import Foundation
import SwiftUI
import RTSCore
import MillicastSDK

struct VideoView: View {

    let renderer: MCVideoSwiftUIView.Renderer

    var body: some View {
        MCVideoSwiftUIView(renderer: renderer, scalingMode: .aspectFit)
    }
}

//
//  MCVideoSwiftUIView.Renderer++.swift
//

import Foundation
import MillicastSDK

extension MCVideoSwiftUIView.Renderer {
    public var underlyingRenderer: MCVideoRenderer {
        switch self {
        case let .accelerated(renderer):
            return renderer
        case let .sampleBuffer(renderer):
            return renderer
        @unknown default:
            fatalError("Unknown renderer type")
        }
    }
}

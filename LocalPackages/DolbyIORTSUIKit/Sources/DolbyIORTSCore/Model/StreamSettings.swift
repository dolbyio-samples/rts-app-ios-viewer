//
//  StreamSettings.swift
//

import Foundation
import SwiftUI

public struct StreamSettings: Codable {

    public enum MultiviewLayout: String, Codable {
        case list
        case single
        case grid
    }

    public enum StreamSortOrder: String, Codable {
        case connectionOrder
        case alphaNumeric
    }

    public enum AudioSelection: Equatable, Codable {
        case firstSource
        case followVideo
        case mainSource
        case source(sourceId: String)
    }

    public var showSourceLabels: Bool
    public var multiviewLayout: MultiviewLayout
    public var streamSortOrder: StreamSortOrder
    public var audioSelection: AudioSelection
    public var audioSources: [String] = []

    public init(showSourceLabels: Bool = true,
                multiviewLayout: MultiviewLayout = .list,
                streamSortOrder: StreamSortOrder = .connectionOrder,
                audioSelection: AudioSelection = .firstSource) {
        self.showSourceLabels = showSourceLabels
        self.multiviewLayout = multiviewLayout
        self.streamSortOrder = streamSortOrder
        self.audioSelection = audioSelection
    }
}

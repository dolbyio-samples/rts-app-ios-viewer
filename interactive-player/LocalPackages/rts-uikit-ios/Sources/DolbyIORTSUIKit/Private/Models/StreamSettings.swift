//
//  StreamSettings.swift
//

import Foundation
import SwiftUI

public struct StreamSettings: Codable, Equatable {

    public enum MultiviewLayout: String, Codable, Equatable {
        case list
        case single
        case grid
    }

    public enum StreamSortOrder: String, Codable, Equatable {
        case connectionOrder
        case alphaNumeric
    }

    public enum AudioSelection: Codable, Equatable {
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
}

extension StreamSettings {
    public static let `default`: StreamSettings = .init(
        showSourceLabels: true,
        multiviewLayout: .list,
        streamSortOrder: .connectionOrder,
        audioSelection: .firstSource
    )
}

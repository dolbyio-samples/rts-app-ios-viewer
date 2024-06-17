//
//  StreamSettings.swift
//

import Foundation
import SwiftUI

struct StreamSettings: Codable, Equatable {

    enum MultiviewLayout: String, Codable, Equatable {
        case list
        case single
        case grid
    }

    enum StreamSortOrder: String, Codable, Equatable {
        case connectionOrder
        case alphaNumeric
    }

    enum AudioSelection: Codable, Equatable {
        case firstSource
        case followVideo
        case mainSource
        case source(sourceId: String)
    }

    var showSourceLabels: Bool
    var multiviewLayout: MultiviewLayout
    var streamSortOrder: StreamSortOrder
    var audioSelection: AudioSelection
    var audioSources: [String] = []
}

extension StreamSettings {
    static let `default`: StreamSettings = .init(
        showSourceLabels: true,
        multiviewLayout: .list,
        streamSortOrder: .connectionOrder,
        audioSelection: .firstSource
    )
}

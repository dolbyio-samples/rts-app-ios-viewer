//
//  StreamSettings.swift
//

import Foundation

public struct StreamSettings {

    public enum MultiviewLayout: String {
        case list = "List view"
        case single = "Single stream view"
        case grid = "Grid view"
    }

    public enum StreamSortOrder: String {
        case connectionOrder = "Connection order"
        case alphaNunmeric = "AlphaNumeric"
    }

    public enum AudioSelection: Equatable {
        case firstSource
        case mainSource
        case followVideo
        case source(label: String)

        public var name: String {
            switch self {
            case .firstSource: return "First source"
            case .followVideo: return "Follow video"
            case .mainSource: return "Main source"
            case .source(label: let l): return l
            }
        }

        public static func == (lhs: AudioSelection, rhs: AudioSelection) -> Bool {
            switch (lhs, rhs) {
            case (.firstSource, .firstSource),
                (.followVideo, .followVideo),
                (.mainSource, .mainSource):
                return true
            case (.source(let a), .source(label: let b)):
                return a == b
            default:
                return false
            }
        }
    }

//    public var showSourceLabels: Bool
//    public var multiviewLayout: MultiviewLayout
//    public var streamSortOrder: StreamSortOrder
//    public var audioSelection: AudioSelection
//
//    public init(showSourceLabels: Bool = true,
//                multiviewLayout: MultiviewLayout = .list,
//                streamSortOrder: StreamSortOrder = .connectionOrder,
//                audioSelection: AudioSelection = .firstSource) {
//        self.showSourceLabels = showSourceLabels
//        self.multiviewLayout = multiviewLayout
//        self.streamSortOrder = streamSortOrder
//        self.audioSelection = audioSelection
//    }
}

//
//  StreamSettings.swift
//

import Foundation

public protocol StreamSettingsProtocol {
    var showSourceLabels: Bool { get set }
    var multiviewLayout: StreamSettings.MultiviewLayout { get set }
    var streamSortOrder: StreamSettings.StreamSortOrder { get set }
    var audioSelection: StreamSettings.AudioSelection { get set }
}

public class StreamSettings: StreamSettingsProtocol, Codable {

    public enum MultiviewLayout: String {
        case list = "List view"
        case single = "Single stream view"
        case grid = "Grid view"
    }

    public enum StreamSortOrder: String {
        case connectionOrder = "Connection order"
        case alphaNunmeric = "AlphaNumeric"
    }

    public enum AudioSelection: Equatable, Codable {
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

        private enum CodingKeys: CodingKey {
            case firstSource, mainSource, followSource, source
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .firstSource:
                try container.encode(self.name, forKey: .firstSource)
            case .mainSource:
                try container.encode(self.name, forKey: .mainSource)
            case .followVideo:
                try container.encode(self.name, forKey: .followSource)
            case let .source(label: label):
                try container.encode(label, forKey: .source)
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            switch container.allKeys.first {
            case .firstSource: self = .firstSource
            case .mainSource: self = .mainSource
            case .followSource: self = .followVideo
            case .source:
                if let label = try? container.decode(String.self, forKey: .source) {
                    self = .source(label: label)
                } else {
                    self = .source(label: "unknown")
                }
            default:
                throw DecodingError.dataCorrupted(
                    .init(codingPath: container.codingPath, debugDescription: "Invalid data")
                )
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

    enum CodingKeys: String, CodingKey {
        case showSourceLabels
        case multiviewLayout
        case streamSortOrder
        case audioSelection
    }

    public var showSourceLabels: Bool
    public var multiviewLayout: MultiviewLayout
    public var streamSortOrder: StreamSortOrder
    public var audioSelection: AudioSelection

    public init(showSourceLabels: Bool = true,
                multiviewLayout: MultiviewLayout = .list,
                streamSortOrder: StreamSortOrder = .connectionOrder,
                audioSelection: AudioSelection = .firstSource) {
        self.showSourceLabels = showSourceLabels
        self.multiviewLayout = multiviewLayout
        self.streamSortOrder = streamSortOrder
        self.audioSelection = audioSelection
    }

    public required init(from decoder: Decoder) throws {
        var rawValue: String

        let container = try decoder.container(keyedBy: CodingKeys.self)
        showSourceLabels = try container.decode(Bool.self, forKey: .showSourceLabels)

        rawValue = try container.decode(String.self, forKey: .multiviewLayout)
        multiviewLayout = MultiviewLayout(rawValue: rawValue) ?? .list

        rawValue = try container.decode(String.self, forKey: .streamSortOrder)
        streamSortOrder = StreamSortOrder(rawValue: rawValue) ?? .connectionOrder

        audioSelection = try container.decode(StreamSettings.AudioSelection.self, forKey: .audioSelection)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(showSourceLabels, forKey: .showSourceLabels)
        try container.encode(multiviewLayout.rawValue, forKey: .multiviewLayout)
        try container.encode(streamSortOrder.rawValue, forKey: .streamSortOrder)
        try container.encode(audioSelection, forKey: .audioSelection)
    }
}

public class GlobalStreamSettings: StreamSettings {

    public override var showSourceLabels: Bool {
        didSet {
            updateUserDefault()
        }
    }

    public override var multiviewLayout: StreamSettings.MultiviewLayout {
        didSet {
            updateUserDefault()
        }
    }

    public override var streamSortOrder: StreamSettings.StreamSortOrder {
        didSet {
            updateUserDefault()
        }
    }

    public override var audioSelection: StreamSettings.AudioSelection {
        didSet {
            updateUserDefault()
        }
    }

    public init() {
        super.init()
        if let data = UserDefaults.standard.object(forKey: "DolbyIORTSCore") as? Data,
           let settings = try? JSONDecoder().decode(StreamSettings.self, from: data) {
            showSourceLabels = settings.showSourceLabels
            multiviewLayout = settings.multiviewLayout
            streamSortOrder = settings.streamSortOrder
            audioSelection = settings.audioSelection
        }
    }

    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }

    private func updateUserDefault() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: "DolbyIORTSCore")
        }
    }
}

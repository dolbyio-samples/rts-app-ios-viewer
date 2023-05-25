//
//  StreamSettingsViewModel.swift
//

import Foundation
import DolbyIORTSCore

final public class StreamSettingsViewModel: ObservableObject {

    @Published private(set) var showSourceLabels: Bool
    @Published private(set) var multiviewLayout: StreamSettings.MultiviewLayout
    @Published private(set) var streamSortOrder: StreamSettings.StreamSortOrder
    @Published private(set) var audioSelection: StreamSettings.AudioSelection

    private var globalSettings: StreamSettings
    private let userDefaults: UserDefaults

    public init() {
        userDefaults = .standard
        globalSettings = .init()
        if let data = userDefaults.object(forKey: "DolbyIORTSCore") as? Data,
           let globalSettings = try? JSONDecoder().decode(StreamSettings.self, from: data) {
            self.globalSettings = globalSettings
        }

        self.showSourceLabels = globalSettings.showSourceLabels
        self.multiviewLayout = globalSettings.multiviewLayout
        self.streamSortOrder = globalSettings.streamSortOrder
        self.audioSelection = globalSettings.audioSelection
    }

    public func setShowSourceLabels(_ showSourceLabels: Bool) {
        self.showSourceLabels = showSourceLabels
        globalSettings.showSourceLabels = showSourceLabels
        updateUserDefault()
    }

    public func setMultiviewLayout(_ multiviewLayout: StreamSettings.MultiviewLayout) {
        self.multiviewLayout = multiviewLayout
        globalSettings.multiviewLayout = multiviewLayout
        updateUserDefault()
    }

    public func setStreamSortOrder(_ streamSortOrder: StreamSettings.StreamSortOrder) {
        self.streamSortOrder = streamSortOrder
        globalSettings.streamSortOrder = streamSortOrder
        updateUserDefault()
    }

    public func setAudioSelection(_ audioSelection: StreamSettings.AudioSelection) {
        self.audioSelection = audioSelection
        globalSettings.audioSelection = audioSelection
        updateUserDefault()
    }

    private func updateUserDefault() {
        if let encoded = try? JSONEncoder().encode(globalSettings) {
            userDefaults.set(encoded, forKey: "DolbyIORTSCore")
        }
    }
}

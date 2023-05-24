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

    public init() {
        self.showSourceLabels = true
        self.multiviewLayout = .list
        self.streamSortOrder = .connectionOrder
        self.audioSelection = .firstSource
    }

    public func setShowSourceLabels(_ showSourceLabels: Bool) {
        self.showSourceLabels = showSourceLabels
    }

    public func setMultiviewLayout(_ multiviewLayout: StreamSettings.MultiviewLayout) {
        self.multiviewLayout = multiviewLayout
    }

    public func setStreamSortOrder(_ streamSortOrder: StreamSettings.StreamSortOrder) {
        self.streamSortOrder = streamSortOrder
    }

    public func setAudioSelection(_ audioSelection: StreamSettings.AudioSelection) {
        self.audioSelection = audioSelection
    }
}

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

    private var settings: StreamSettingsProtocol

    public init(settings: StreamSettingsProtocol) {
        self.settings = settings
        self.showSourceLabels = settings.showSourceLabels
        self.multiviewLayout = settings.multiviewLayout
        self.streamSortOrder = settings.streamSortOrder
        self.audioSelection = settings.audioSelection
    }

    func setShowSourceLabels(_ showSourceLabels: Bool) {
        self.showSourceLabels = showSourceLabels
        settings.showSourceLabels = showSourceLabels
    }

    func setMultiviewLayout(_ multiviewLayout: StreamSettings.MultiviewLayout) {
        self.multiviewLayout = multiviewLayout
        settings.multiviewLayout = multiviewLayout
    }

    func setStreamSortOrder(_ streamSortOrder: StreamSettings.StreamSortOrder) {
        self.streamSortOrder = streamSortOrder
        settings.streamSortOrder = streamSortOrder
    }

    func setAudioSelection(_ audioSelection: StreamSettings.AudioSelection) {
        self.audioSelection = audioSelection
        settings.audioSelection = audioSelection
    }
}

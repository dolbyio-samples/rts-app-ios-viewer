//
//  SettingsViewModel.swift
//

import Combine
import Foundation
import DolbyIOUIKit
import DolbyIORTSCore
import SwiftUI

final class SettingsViewModel: ObservableObject {

    private let settingsManager: SettingsManager
    private(set) var settingsScreenTitle: LocalizedStringKey
    private var subscriptions: [AnyCancellable] = []

    @Published private(set) var showSourceLabels: Bool
    @Published private(set) var multiviewLayout: StreamSettings.MultiviewLayout
    @Published private(set) var streamSortOrder: StreamSettings.StreamSortOrder
    @Published private(set) var audioSelection: StreamSettings.AudioSelection

    @Published private(set) var mutliviewSelectedLabelKey: LocalizedStringKey
    @Published private(set) var multiviewSelectionItems: [SelectionsGroup.Item] = []

    @Published private(set) var streamSortOrderSelectedLabelKey: LocalizedStringKey
    @Published private(set) var streamSortOrderSelectionItems: [SelectionsGroup.Item] = []

    @Published private(set) var audioSelectedLabelKey: LocalizedStringKey
    @Published private(set) var audioSelectionsItems: [SelectionsGroup.Item] = []

    init(settingsManager: SettingsManager = .shared) {
        self.settingsManager = settingsManager
        if case .global = settingsManager.mode {
            self.settingsScreenTitle = "settings.global.title.label"
        } else {
            self.settingsScreenTitle = "settings.stream.title.label"
        }

        showSourceLabels = settingsManager.settings.showSourceLabels
        multiviewLayout = settingsManager.settings.multiviewLayout
        streamSortOrder = settingsManager.settings.streamSortOrder
        audioSelection = settingsManager.settings.audioSelection

        mutliviewSelectedLabelKey = "place.holder"
        streamSortOrderSelectedLabelKey = "place.holder"
        audioSelectedLabelKey = "place.holder"

        setupSettingsObservers()
    }

    func setShowSourceLabels(_ showSourceLabels: Bool) {
        settingsManager.settings.showSourceLabels = showSourceLabels
    }

    func setMultiviewLayout(_ multiviewLayout: StreamSettings.MultiviewLayout) {
        settingsManager.settings.multiviewLayout = multiviewLayout
    }

    func selectMultiviewLayout(with index: Int) {
        switch index {
        case 1: setMultiviewLayout(.single)
        default: setMultiviewLayout(.list)
        }
    }

    func setStreamSortOrder(_ streamSortOrder: StreamSettings.StreamSortOrder) {
        settingsManager.settings.streamSortOrder = streamSortOrder
    }

    func selectStreamSortOrder(with index: Int) {
        switch index {
        case 1: setStreamSortOrder(.alphaNumeric)
        default: setStreamSortOrder(.connectionOrder)
        }
    }

    func setAudioSelection(_ audioSelection: StreamSettings.AudioSelection) {
        settingsManager.settings.audioSelection = audioSelection
    }

    func selectAudioSelection(with index: Int) {
        switch index {
        case 0: setAudioSelection(.firstSource)
        case 1: setAudioSelection(.followVideo)
        case 2: setAudioSelection(.mainSource)
        default:
            if case .stream = settingsManager.mode {
                if settingsManager.settings.audioSources.isEmpty == false {
                    let label = settingsManager.settings.audioSources[index - 3]
                    setAudioSelection(.source(sourceId: label))
                }
            }
        }
    }
}

extension SettingsViewModel {

    private func setupSettingsObservers() {
        settingsManager.settingsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] settings in
                guard let self = self else { return }
                self.updateSettings(settings)
            }
            .store(in: &subscriptions)
    }

    private func updateSettings(_ settings: StreamSettings) {
        self.showSourceLabels = settings.showSourceLabels
        self.multiviewLayout = settings.multiviewLayout
        self.streamSortOrder = settings.streamSortOrder
        self.audioSelection = settings.audioSelection

        updateMultiviewSelection()
        updateStreamSortOrderSelection()
        updateAudioSelection()
    }

    private func updateMultiviewSelection() {
        multiviewSelectionItems = [
            .init(key: "default-multi-view-layout.list-view.label",
                  bundle: .module,
                  selected: multiviewLayout == .list),
            .init(key: "default-multi-view-layout.single-stream-view.label",
                  bundle: .module,
                  selected: multiviewLayout == .single)
        ]

        switch multiviewLayout {
        case .list:
            mutliviewSelectedLabelKey = "default-multi-view-layout.list-view.label"
        case .single:
            mutliviewSelectedLabelKey = "default-multi-view-layout.single-stream-view.label"
        case .grid:
            mutliviewSelectedLabelKey = "default-multi-view-layout.grid-view.label"
        }
    }

    private func updateStreamSortOrderSelection() {
        streamSortOrderSelectionItems = [
            .init(key: "stream-sort-order.connection-order.label",
                  bundle: .module,
                  selected: streamSortOrder == .connectionOrder),
            .init(key: "stream-sort-order.alphanumeric.label",
                  bundle: .module,
                  selected: streamSortOrder == .alphaNumeric)
        ]

        switch streamSortOrder {
        case .connectionOrder:
            streamSortOrderSelectedLabelKey = "stream-sort-order.connection-order.label"
        case .alphaNumeric:
            streamSortOrderSelectedLabelKey = "stream-sort-order.alphanumeric.label"
        }
    }

    private func updateAudioSelection() {
        var items: [SelectionsGroup.Item]

        switch settingsManager.mode {
        case .global:
            items = [
                .init(key: "audio-selection.first-source.label",
                      bundle: .module,
                      selected: audioSelection == .firstSource),
                .init(key: "audio-selection.follow-video.label",
                      bundle: .module,
                      selected: audioSelection == .followVideo)]
        default:
            items = [
                .init(key: "audio-selection.first-source.label",
                      bundle: .module,
                      selected: audioSelection == .firstSource),
                .init(key: "audio-selection.follow-video.label",
                      bundle: .module,
                      selected: audioSelection == .followVideo),
                .init(key: "audio-selection.main-source.label",
                      bundle: .module,
                      selected: audioSelection == .mainSource)
            ]

            settingsManager.settings.audioSources.forEach {
                items.append(
                    .init(key: LocalizedStringKey($0),
                          bundle: .module,
                          selected: audioSelection == .source(sourceId: $0))
                )
            }
        }

        switch audioSelection {
        case .firstSource: audioSelectedLabelKey = "audio-selection.first-source.label"
        case .followVideo: audioSelectedLabelKey = "audio-selection.follow-video.label"
        case .mainSource: audioSelectedLabelKey = "audio-selection.main-source.label"
        case .source(sourceId: let sourceId): audioSelectedLabelKey = LocalizedStringKey(sourceId)
        }

        audioSelectionsItems = items
    }
}

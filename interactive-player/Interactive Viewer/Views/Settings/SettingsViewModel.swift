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
    private let mode: SettingsMode

    private(set) var settingsScreenTitle: LocalizedStringKey
    private var subscriptions: [AnyCancellable] = []

    private var settings: StreamSettings = .default {
        didSet {
            updateState(for: settings)
        }
    }

    @Published private(set) var showSourceLabels = StreamSettings.default.showSourceLabels
    @Published private(set) var multiviewLayout = StreamSettings.default.multiviewLayout
    @Published private(set) var streamSortOrder = StreamSettings.default.streamSortOrder
    @Published private(set) var audioSelection = StreamSettings.default.audioSelection

    @Published private(set) var mutliviewSelectedLabelKey: LocalizedStringKey
    @Published private(set) var multiviewSelectionItems: [SelectionsGroup.Item] = []

    @Published private(set) var streamSortOrderSelectedLabelKey: LocalizedStringKey
    @Published private(set) var streamSortOrderSelectionItems: [SelectionsGroup.Item] = []

    @Published private(set) var audioSelectedLabelKey: LocalizedStringKey
    @Published private(set) var audioSelectionsItems: [SelectionsGroup.Item] = []

    init(
        mode: SettingsMode,
        settingsManager: SettingsManager = .shared
    ) {
        self.settingsManager = settingsManager
        self.mode = mode

        switch mode {
        case .global:
            self.settingsScreenTitle = "settings.global.title.label"
        case .stream:
            self.settingsScreenTitle = "settings.stream.title.label"
        }

        mutliviewSelectedLabelKey = "place.holder"
        streamSortOrderSelectedLabelKey = "place.holder"
        audioSelectedLabelKey = "place.holder"

        setupSettingsObservers()
    }

    func setShowSourceLabels(_ showSourceLabels: Bool) {
        var updatedSettings = settings
        updatedSettings.showSourceLabels = showSourceLabels

        settingsManager.update(settings: updatedSettings, for: mode)
    }

    func setMultiviewLayout(_ multiviewLayout: StreamSettings.MultiviewLayout) {
        var updatedSettings = settings
        updatedSettings.multiviewLayout = multiviewLayout

        settingsManager.update(settings: updatedSettings, for: mode)
    }

    func selectMultiviewLayout(with index: Int) {
        switch index {
        case 1: setMultiviewLayout(.single)
        case 2: setMultiviewLayout(.grid)
        default: setMultiviewLayout(.list)
        }
    }

    func setStreamSortOrder(_ streamSortOrder: StreamSettings.StreamSortOrder) {
        var updatedSettings = settings
        updatedSettings.streamSortOrder = streamSortOrder

        settingsManager.update(settings: updatedSettings, for: mode)
    }

    func selectStreamSortOrder(with index: Int) {
        switch index {
        case 1: setStreamSortOrder(.alphaNumeric)
        default: setStreamSortOrder(.connectionOrder)
        }
    }

    func setAudioSelection(_ audioSelection: StreamSettings.AudioSelection) {
        var updatedSettings = settings
        updatedSettings.audioSelection = audioSelection

        settingsManager.update(settings: updatedSettings, for: mode)
    }

    func selectAudioSelection(with index: Int) {
        switch index {
        case 0: setAudioSelection(.firstSource)
        case 1: setAudioSelection(.followVideo)
        case 2: setAudioSelection(.mainSource)
        default:
            if case .stream = mode {
                if settings.audioSources.isEmpty == false {
                    let label = settings.audioSources[index - 3]
                    setAudioSelection(.source(sourceId: label))
                }
            }
        }
    }
}

extension SettingsViewModel {

    private func setupSettingsObservers() {
        settingsManager.publisher(for: mode)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] settings in
                guard let self = self else { return }
                self.settings = settings
            }
            .store(in: &subscriptions)
    }

    private func updateState(for settings: StreamSettings) {
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
                  selected: multiviewLayout == .list),
            .init(key: "default-multi-view-layout.single-stream-view.label",
                  selected: multiviewLayout == .single),
            .init(key: "default-multi-view-layout.grid-view.label",
                  selected: multiviewLayout == .grid)
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
                  selected: streamSortOrder == .connectionOrder),
            .init(key: "stream-sort-order.alphanumeric.label",
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

        switch mode {
        case .global:
            items = [
                .init(key: "audio-selection.first-source.label",
                          selected: audioSelection == .firstSource),
                .init(key: "audio-selection.follow-video.label",
                          selected: audioSelection == .followVideo)]
        default:
            items = [
                .init(key: "audio-selection.first-source.label",
                          selected: audioSelection == .firstSource),
                .init(key: "audio-selection.follow-video.label",
                          selected: audioSelection == .followVideo),
                .init(key: "audio-selection.main-source.label",
                          selected: audioSelection == .mainSource)
            ]

            settings.audioSources.forEach {
                items.append(
                    .init(key: LocalizedStringKey($0),
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

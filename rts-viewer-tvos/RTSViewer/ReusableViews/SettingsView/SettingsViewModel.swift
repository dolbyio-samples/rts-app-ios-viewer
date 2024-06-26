//
//  SettingsViewModel.swift
//

import Foundation
import MillicastSDK
import RTSCore

@MainActor
final class SettingViewModel: ObservableObject {
    private let rendererRegistry: RendererRegistry

    let source: StreamSource
    let videoQualityList: [VideoQuality]
    let selectedVideoQuality: VideoQuality

    init(source: StreamSource, videoQualityList: [VideoQuality], selectedVideoQuality: VideoQuality, rendererRegistry: RendererRegistry) {
        self.source = source
        self.videoQualityList = videoQualityList
        self.selectedVideoQuality = selectedVideoQuality
        self.rendererRegistry = rendererRegistry
    }

    func select(videoQuality: VideoQuality) async throws {
        let renderer = rendererRegistry.acceleratedRenderer(for: source)
        switch videoQuality {
        case .auto:
            try await source.videoTrack.enable(renderer: renderer.underlyingRenderer, promote: true)
        case let .quality(underlyingLayer):
            try await source.videoTrack.enable(renderer: renderer.underlyingRenderer, layer: MCRTSRemoteVideoTrackLayer(layer: underlyingLayer), promote: true)
        }
    }
}

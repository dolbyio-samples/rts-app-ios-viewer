//
//  SettingsViewModel.swift
//

import Foundation
import MillicastSDK
import RTSComponentKit

@MainActor
final class SettingViewModel: ObservableObject {
    private let rendererRegistry: RendererRegistry

    let source: Source
    let videoQualityList: [VideoQuality]
    let selectedVideoQuality: VideoQuality

    init(source: Source, videoQualityList: [VideoQuality], selectedVideoQuality: VideoQuality, rendererRegistry: RendererRegistry) {
        self.source = source
        self.videoQualityList = videoQualityList
        self.selectedVideoQuality = selectedVideoQuality
        self.rendererRegistry = rendererRegistry
    }

    func select(videoQuality: VideoQuality) async throws {
        let renderer = rendererRegistry.renderer(for: source)
        switch videoQuality {
        case .auto:
            try await source.videoTrack.enable(renderer: renderer.underlyingRenderer, promote: true)
        case .high(let layer), .medium(let layer), .low(let layer):
            try await source.videoTrack.enable(renderer: renderer.underlyingRenderer, layer: MCRTSRemoteVideoTrackLayer(layer: layer), promote: true)
        }
    }
}

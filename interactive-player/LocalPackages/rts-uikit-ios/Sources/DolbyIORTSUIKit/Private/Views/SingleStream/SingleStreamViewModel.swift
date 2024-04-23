//
//  SingleStreamViewModel.swift
//

import Combine
import DolbyIORTSCore
import Foundation

final class SingleStreamViewModel {

    let videoViewModels: [VideoRendererViewModel]
    let selectedVideoSource: StreamSource
    let settingsMode: SettingsMode
    let viewRendererProvider: ViewRendererProvider

    init(
        videoViewModels: [VideoRendererViewModel],
        selectedVideoSource: StreamSource,
        streamDetail: StreamDetail,
        viewRendererProvider: ViewRendererProvider
    ) {
        self.videoViewModels = videoViewModels
        self.selectedVideoSource = selectedVideoSource
        self.settingsMode = .stream(streamName: streamDetail.streamName, accountID: streamDetail.accountID)
        self.viewRendererProvider = viewRendererProvider
    }

    func streamSource(for id: UUID) -> StreamSource? {
        videoViewModels.first { $0.streamSource.id == id }?.streamSource
    }
}

//
//  SingleStreamViewModel.swift
//

import Combine
import DolbyIORTSCore
import Foundation

final class SingleStreamViewModel {

    let videoViewModels: [VideoRendererViewModel]
    let selectedVideoSource: StreamSource

    init(videoViewModels: [VideoRendererViewModel], selectedVideoSource: StreamSource) {
        self.videoViewModels = videoViewModels
        self.selectedVideoSource = selectedVideoSource
    }

    func streamSource(for id: UUID) -> StreamSource? {
        videoViewModels.first { $0.streamSource.id == id }?.streamSource
    }
}

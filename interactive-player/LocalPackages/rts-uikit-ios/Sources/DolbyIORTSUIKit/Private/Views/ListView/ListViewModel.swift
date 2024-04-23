//
//  ListViewModel.swift
//

import DolbyIORTSCore
import Foundation

final class ListViewModel {

    let primaryVideoViewModel: VideoRendererViewModel
    let secondaryVideoViewModels: [VideoRendererViewModel]
    let mainViewRendererProvider: ViewRendererProvider
    let thumbnailViewRendererProvider: ViewRendererProvider

    init(
        primaryVideoViewModel: VideoRendererViewModel,
        secondaryVideoViewModels: [VideoRendererViewModel],
        mainViewRendererProvider: ViewRendererProvider,
        thumbnailViewRendererProvider: ViewRendererProvider
    ) {
        self.primaryVideoViewModel = primaryVideoViewModel
        self.secondaryVideoViewModels = secondaryVideoViewModels
        self.mainViewRendererProvider = mainViewRendererProvider
        self.thumbnailViewRendererProvider = thumbnailViewRendererProvider
    }
}

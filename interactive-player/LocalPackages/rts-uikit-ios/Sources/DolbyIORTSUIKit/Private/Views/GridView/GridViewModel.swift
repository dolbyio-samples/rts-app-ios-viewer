//
//  GridViewModel.swift
//  
//

import DolbyIORTSCore

final class GridViewModel {

    var allVideoViewModels: [VideoRendererViewModel]
    let viewRendererProvider: ViewRendererProvider

    init(
        primaryVideoViewModel: VideoRendererViewModel,
        secondaryVideoViewModels: [VideoRendererViewModel],
        viewRendererProvider: ViewRendererProvider
    ) {
        self.allVideoViewModels = [primaryVideoViewModel]
        self.allVideoViewModels.append(contentsOf: secondaryVideoViewModels)
        self.viewRendererProvider = viewRendererProvider
    }
}

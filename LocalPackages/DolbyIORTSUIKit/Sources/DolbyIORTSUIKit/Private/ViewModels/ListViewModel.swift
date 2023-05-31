//
//  ListViewModel.swift
//

import DolbyIORTSCore
import Foundation

final class ListViewModel {

    let primaryVideoViewModel: VideoRendererViewModel
    let secondaryVideoViewModels: [VideoRendererViewModel]

    init(primaryVideoViewModel: VideoRendererViewModel, secondaryVideoViewModels: [VideoRendererViewModel]) {
        self.primaryVideoViewModel = primaryVideoViewModel
        self.secondaryVideoViewModels = secondaryVideoViewModels
    }
}

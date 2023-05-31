//
//  SingleStreamViewModel.swift
//
    
import Foundation
import DolbyIORTSCore

final class SingleStreamViewModel {
    let videoViewModels: [VideoRendererViewModel]

    init(videoViewModels: [VideoRendererViewModel]) {
        self.videoViewModels = videoViewModels
    }
}


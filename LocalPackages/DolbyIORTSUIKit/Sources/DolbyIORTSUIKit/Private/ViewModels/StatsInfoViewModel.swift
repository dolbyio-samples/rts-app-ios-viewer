//
//  StatsInfoViewModel.swift
//

import Combine
import DolbyIORTSCore
import Foundation

final class StatsInfoViewModel: ObservableObject {
    private let streamSource: StreamSource

    init(streamSource: StreamSource) {
        self.streamSource = streamSource
    }
}

//
//  SourceId+Display.swift
//

import RTSCore
import DolbyIOUIKit
import SwiftUI

extension SourceID {
    var displayLabel: String {
        switch self {
        case .main:
            return LocalizedStringKey("video-view.main.label").toString(with: .main)
        case let .other(sourceId: sourceId):
            return sourceId
        }
    }
}

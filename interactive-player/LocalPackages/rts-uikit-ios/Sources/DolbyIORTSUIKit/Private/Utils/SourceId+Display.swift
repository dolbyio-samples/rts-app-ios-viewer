//
//  SourceId+Display.swift
//

import DolbyIORTSCore
import DolbyIOUIKit
import SwiftUI

extension SourceID {
    var displayLabel: String {
        return switch self {
        case .main:
            LocalizedStringKey("video-view.main.label").toString(with: .module)
        case let .other(sourceId: sourceId):
            sourceId
        }
    }
}

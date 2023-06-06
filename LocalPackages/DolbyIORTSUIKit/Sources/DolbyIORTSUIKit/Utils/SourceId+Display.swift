//
//  SourceId+Display.swift
//

import DolbyIORTSCore
import DolbyIOUIKit
import SwiftUI

extension StreamSource.SourceId {
    var displayLabel: String {
        self.value ?? LocalizedStringKey("video-view.main.label").toString(with: .module)
    }
}

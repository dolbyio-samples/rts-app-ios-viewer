//
//  ThemeManager.swift
//

import Combine
import Foundation
import SwiftUI

public class ThemeManager: ObservableObject {
    static public let shared: ThemeManager = ThemeManager(theme: DefaultTheme())

    /// A current theme of an app.
    @Published public var theme: Theme

    init(theme: Theme) {
        self.theme = theme
    }
}

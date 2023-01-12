//
//  ThemeManager.swift
//

import Combine
import Foundation
import SwiftUI

public class ThemeManager: ObservableObject {
    static public let shared: ThemeManager = ThemeManager()

    /// A current theme of an app.
    @Published public private(set) var theme: Theme

    private init() {
        self.theme = DefaultTheme()
    }
}

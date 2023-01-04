//
//  File.swift
//  
//
//  Created by Raveendran, Aravind on 7/1/2023.
//

import SwiftUI

struct ClearButtonStyle: ButtonStyle {
    let isFocused: Bool
    let focusedBackgroundColor: Color?

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(minWidth: 48, minHeight: 48)
            .background(isFocused ? focusedBackgroundColor : .clear)
    }
}

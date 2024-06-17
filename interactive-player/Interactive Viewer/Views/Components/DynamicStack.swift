//
//  DynamicStack.swift
//

import DolbyIOUIKit
import SwiftUI

struct DynamicStack<Content: View>: View {
    let horizontalAlignment = HorizontalAlignment.center
    let verticalAlignment = VerticalAlignment.center
    let spacing: CGFloat?
    @ViewBuilder var content: () -> Content
    @State private var deviceOrientation: UIDeviceOrientation = UIDeviceOrientation.portrait

    var body: some View {
        ZStack {
            if deviceOrientation.isPortrait {
                vStack
            } else {
                hStack
            }
        }
        .onRotate { newOrientation in
            if !newOrientation.isFlat && newOrientation.isValidInterfaceOrientation {
                deviceOrientation = newOrientation
            }
        }
    }
}

private extension DynamicStack {
    var hStack: some View {
        HStack(
            alignment: verticalAlignment,
            spacing: spacing,
            content: content
        )
        .onRotate { newOrientation in
            if !newOrientation.isFlat && newOrientation.isValidInterfaceOrientation {
                deviceOrientation = newOrientation
            }
        }
    }

    var vStack: some View {
        VStack(
            alignment: horizontalAlignment,
            spacing: spacing,
            content: content
        )
        .onRotate { newOrientation in
            if !newOrientation.isFlat && newOrientation.isValidInterfaceOrientation {
                deviceOrientation = newOrientation
            }
        }
    }
}

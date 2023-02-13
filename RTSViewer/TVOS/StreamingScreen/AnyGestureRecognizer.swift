//
//  AnyGestureRecognizer.swift
//

import Foundation
import SwiftUI

struct AnyGestureRecognizer: UIViewRepresentable {
    @Binding var triggered: Bool

    func makeCoordinator() -> AnyGestureRecognizer.Coordinator {
        return AnyGestureRecognizer.Coordinator(recognizer: self)
    }

    func makeUIView(context: UIViewRepresentableContext<AnyGestureRecognizer>) -> UIView {
        let view = AnyGestureView()
        view.backgroundColor = .clear
        let left = UISwipeGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.left))
        left.direction = .left

        let right = UISwipeGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.right))
        right.direction = .right

        let up = UISwipeGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.up))
        up.direction = .up

        let down = UISwipeGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.down))
        down.direction = .down

        view.addGestureRecognizer(left)
        view.addGestureRecognizer(right)
        view.addGestureRecognizer(up)
        view.addGestureRecognizer(down)
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<AnyGestureRecognizer>) {

    }

    class Coordinator: NSObject {
        var parent: AnyGestureRecognizer

        init(recognizer: AnyGestureRecognizer) {
            parent = recognizer
        }

        func clicked() {
            trigger()
        }

        @objc func left() {
            trigger()
        }

        @objc func right() {
            trigger()
        }

        @objc func up() {
            trigger()
        }

        @objc func down() {
            trigger()
        }

        func trigger() {
            withAnimation {
                parent.triggered = true
            }
        }
    }

    class AnyGestureView: UIView {
        weak var delegate: Coordinator?

        override init(frame: CGRect) {
            super.init(frame: frame)
        }

        override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            if (
                event?.allPresses.map({ $0.type }).contains(.select) ?? false ||
                event?.allPresses.map({ $0.type }).contains(.playPause) ?? false ||
                event?.allPresses.map({ $0.type }).contains(.leftArrow) ?? false ||
                event?.allPresses.map({ $0.type }).contains(.rightArrow) ?? false ||
                event?.allPresses.map({ $0.type }).contains(.upArrow) ?? false ||
                event?.allPresses.map({ $0.type }).contains(.downArrow) ?? false
            ) {
                delegate?.clicked()
            } else {
                superview?.pressesEnded(presses, with: event)
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var canBecomeFocused: Bool {
            return true
        }
    }
}

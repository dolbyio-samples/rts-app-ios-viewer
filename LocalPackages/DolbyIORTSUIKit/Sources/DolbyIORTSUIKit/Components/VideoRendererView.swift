//
//  VideoRenderer.swift
//

import DolbyIORTSCore
import Foundation
import SwiftUI

struct VideoRendererView: UIViewRepresentable {
    private let viewProvider: SourceViewProviding

    init(viewProvider: SourceViewProviding) {
        self.viewProvider = viewProvider
    }

    func makeUIView(context: Context) -> UIView {
        let containerView = ContainerView<UIView>()
        containerView.updateChildView(viewProvider.playbackView)

        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let containerView = uiView as? ContainerView<UIView> else {
            return
        }
        containerView.updateChildView(viewProvider.playbackView)
    }
}

private final class ContainerView<ChildView: UIView>: UIView {

    private var childView: ChildView?

    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateChildView(_ view: ChildView) {
        childView?.removeFromSuperview()

        view.translatesAutoresizingMaskIntoConstraints = false

        addSubview(view)
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: view.topAnchor),
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        childView = view

        setNeedsLayout()
        layoutIfNeeded()
    }
}

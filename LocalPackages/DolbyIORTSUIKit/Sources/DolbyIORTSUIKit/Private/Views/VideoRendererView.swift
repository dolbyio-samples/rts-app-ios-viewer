//
//  VideoRendererView.swift
//

import DolbyIORTSCore
import SwiftUI

struct VideoRendererView: View {
    @ObservedObject private var viewModel: VideoRendererViewModel
    @State var identifier = UUID()
    private let maxWidth: CGFloat
    private var maxHeight: CGFloat
    private var contentMode: VideoRendererContentMode

    init(source: StreamSource, maxWidth: CGFloat, maxHeight: CGFloat, contentMode: VideoRendererContentMode) {
        self.viewModel = .init(streamSource: source)
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
        self.contentMode = contentMode
    }

    var body: some View {
        HStack {
            let viewRenderer = viewModel.getRenderer(for: identifier.uuidString)
            let videoSize: CGSize = {
                switch contentMode {
                case .aspectFit:
                    return viewRenderer.videoViewDisplaySize(
                        forAvailableScreenWidth: maxWidth,
                        availableScreenHeight: maxHeight,
                        shouldCrop: false
                    )
                case .aspectFill:
                    return viewRenderer.videoViewDisplaySize(
                        forAvailableScreenWidth: maxWidth,
                        availableScreenHeight: maxHeight,
                        shouldCrop: true
                    )
                case .scaleToFill:
                    return CGSize(width: maxWidth, height: maxHeight)
                }
            }()

            VideoRendererViewInteral(viewRenderer: viewRenderer)
                .frame(width: videoSize.width, height: videoSize.height)
                .onAppear {
                    viewModel.playVideo(for: viewModel.streamSource)
                }
                .onDisappear {
                    viewModel.stopVideo(for: viewModel.streamSource)
                    viewModel.removeRenderer(for: identifier.uuidString)
                }
        }
        .frame(width: maxWidth, height: maxHeight)
    }
}

private struct VideoRendererViewInteral: UIViewRepresentable {
    private let viewRenderer: StreamSourceViewRenderer

    init(viewRenderer: StreamSourceViewRenderer) {
        self.viewRenderer = viewRenderer
    }

    func makeUIView(context: Context) -> UIView {
        let containerView = ContainerView<UIView>()
        containerView.updateChildView(viewRenderer.playbackView)
        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let containerView = uiView as? ContainerView<UIView> else {
            return
        }
        containerView.updateChildView(viewRenderer.playbackView)
    }
}

private final class ContainerView<ChildView: UIView>: UIView {

    private var childView: ChildView?

    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: .zero, height: .zero))
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

//
//  VideoRendererView.swift
//

import DolbyIORTSCore
import DolbyIOUIKit
import SwiftUI

struct VideoRendererView: View {
    private let viewModel: VideoRendererViewModel
    private let maxWidth: CGFloat
    private let maxHeight: CGFloat
    private let contentMode: VideoRendererContentMode
    private let action: ((StreamSource) -> Void)?

    init(
        viewModel: VideoRendererViewModel,
        maxWidth: CGFloat,
        maxHeight: CGFloat,
        contentMode: VideoRendererContentMode,
        action: ((StreamSource) -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
        self.contentMode = contentMode
        self.action = action

        Task {
            viewModel.playVideo(for: viewModel.streamSource)
        }
    }

    @ViewBuilder
    private var audioPlaybackIndicatorView: some View {
        if viewModel.showAudioIndicator {
            Rectangle()
                .stroke(
                    Color(uiColor: UIColor.Primary.neonPurple400),
                    lineWidth: Layout.border2x
                )
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func showLabel(for source: StreamSource) -> some View {
        if viewModel.showSourceLabel {
            SourceLabel(sourceId: source.sourceId.displayLabel)
                .padding(5)
        } else {
            EmptyView()
        }
    }

    var body: some View {
        let viewRenderer = viewModel.viewRenderer
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
            .overlay(alignment: .bottomLeading) {
                showLabel(for: viewModel.streamSource)
            }
            .overlay {
                audioPlaybackIndicatorView
            }
            .onTapGesture {
                action?(viewModel.streamSource)
            }
            .onDisappear {
                viewModel.stopVideo(for: viewModel.streamSource)
            }
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

//
//  VideoRendererView.swift
//

import DolbyIOUIKit
import MillicastSDK
import RTSCore
import SwiftUI

struct VideoRendererView: View {
    @ObservedObject private var viewModel: VideoRendererViewModel
    @State private var videoSize: CGSize
    private let accessibilityIdentifier: String
    private let action: ((StreamSource) -> Void)?
    private var theme = ThemeManager.shared.theme

    init(
        source: StreamSource,
        showSourceLabel: Bool,
        showAudioIndicator: Bool,
        maxWidth: CGFloat,
        maxHeight: CGFloat,
        accessibilityIdentifier: String,
        rendererRegistry: RendererRegistry,
        action: ((StreamSource) -> Void)? = nil
    ) {
        let viewModel = VideoRendererViewModel(
            source: source,
            showSourceLabel: showSourceLabel,
            showAudioIndicator: showAudioIndicator,
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            rendererRegistry: rendererRegistry
        )
        self.videoSize = viewModel.videoSize
        self.accessibilityIdentifier = accessibilityIdentifier
        self.action = action
        self.viewModel = viewModel
    }

    var body: some View {
        let tileSize = viewModel.tileSize(from: videoSize)
        VideoRendererViewInternal(viewModel: viewModel)
            .onVideoSizeChange {
                videoSize = $0
            }
            .frame(width: tileSize.width, height: tileSize.height)
            .accessibilityIdentifier(accessibilityIdentifier)
    }
}

private struct VideoRendererViewInternal: UIViewControllerRepresentable {
    class VideoViewDelegate: MCVideoViewDelegate {
        var onVideoSizeChange: ((CGSize) -> Void)?

        func didChangeVideoSize(_ size: CGSize) {
            onVideoSizeChange?(size)
        }
    }

    private let viewModel: VideoRendererViewModel
    private let delegate = VideoViewDelegate()

    init(viewModel: VideoRendererViewModel) {
        self.viewModel = viewModel
    }

    func makeUIViewController(context: Context) -> VideoViewController {
        VideoViewController(
            renderer: viewModel.renderer,
            delegate: delegate
        )
    }

    func updateUIViewController(_ videoViewController: VideoViewController, context: Context) {
        guard videoViewController.renderer != viewModel.renderer else { return }
        videoViewController.update(renderer: viewModel.renderer, delegate: delegate)
    }
}

private extension VideoRendererViewInternal {
    func onVideoSizeChange(_ perform: @escaping (CGSize) -> Void) -> some View {
        delegate.onVideoSizeChange = perform
        return self
    }
}

private class VideoViewController: UIViewController {
    private(set) var renderer: MCCMSampleBufferVideoRenderer
    private weak var delegate: MCVideoViewDelegate?
    private let videoView: MCSampleBufferVideoUIView

    init(renderer: MCCMSampleBufferVideoRenderer, delegate: MCVideoViewDelegate) {
        self.renderer = renderer
        self.delegate = delegate
        self.videoView = MCSampleBufferVideoUIView(frame: .zero, renderer: renderer)

        super.init(nibName: nil, bundle: nil)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        videoView.translatesAutoresizingMaskIntoConstraints = false
        videoView.delegate = delegate
        view.addSubview(videoView)

        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: videoView.topAnchor),
            view.leadingAnchor.constraint(equalTo: videoView.leadingAnchor),
            videoView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            videoView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    func update(renderer: MCCMSampleBufferVideoRenderer, delegate: MCVideoViewDelegate) {
        self.renderer = renderer
        self.delegate = delegate
        videoView.updateRenderer(renderer)
    }
}

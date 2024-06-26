//
//  VideoRendererView.swift
//

import RTSCore
import DolbyIOUIKit
import MillicastSDK
import SwiftUI

struct VideoRendererView: View {
    @ObservedObject private var viewModel: VideoRendererViewModel
    private let accessibilityIdentifier: String
    private let action: ((StreamSource) -> Void)?

    @State private var videoSize: CGSize
    @ObservedObject private var themeManager = ThemeManager.shared
    @AppConfiguration(\.showDebugFeatures) var showDebugFeatures

    init(
        source: StreamSource,
        isSelectedVideoSource: Bool,
        isSelectedAudioSource: Bool,
        isPiPView: Bool,
        showSourceLabel: Bool,
        showAudioIndicator: Bool,
        maxWidth: CGFloat,
        maxHeight: CGFloat,
        accessibilityIdentifier: String,
        preferredVideoQuality: VideoQuality,
        subscriptionManager: SubscriptionManager,
        videoTracksManager: VideoTracksManager,
        action: ((StreamSource) -> Void)? = nil
    ) {
        let viewModel = VideoRendererViewModel(
            source: source,
            isSelectedVideoSource: isSelectedVideoSource,
            isSelectedAudioSource: isSelectedAudioSource,
            isPiPView: isPiPView,
            showSourceLabel: showSourceLabel,
            showAudioIndicator: showAudioIndicator,
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            preferredVideoQuality: preferredVideoQuality,
            subscriptionManager: subscriptionManager,
            videoTracksManager: videoTracksManager
        )
        videoSize = viewModel.videoSize
        self.accessibilityIdentifier = accessibilityIdentifier
        self.action = action
        self.viewModel = viewModel
    }

    private var theme: Theme {
        themeManager.theme
    }

    @ViewBuilder
    private var audioPlaybackIndicatorView: some View {
        if viewModel.showAudioIndicator {
            Rectangle()
                .stroke(
                    Color(uiColor: theme.primary400),
                    lineWidth: Layout.border2x
                )
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private var sourceLabelView: some View {
        if viewModel.showSourceLabel {
            SourceLabel(sourceId: viewModel.source.sourceId.displayLabel)
                .accessibilityIdentifier("SourceID.\(viewModel.source.sourceId.displayLabel)")
                .padding(Layout.spacing0_5x)
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private var videoQualityIndicatorView: some View {
        if showDebugFeatures, let videoQualityIndicatorText = viewModel.currentVideoQuality.displayText.first?.uppercased() {
            Text(
                verbatim: videoQualityIndicatorText,
                font: .custom("AvenirNext-Regular", size: FontSize.caption1, relativeTo: .caption)
            )
            .foregroundColor(Color(uiColor: themeManager.theme.onPrimary))
            .padding(.horizontal, Layout.spacing1x)
            .background(Color(uiColor: themeManager.theme.neutral400))
            .cornerRadius(Layout.cornerRadius4x)
            .padding(Layout.spacing0_5x)
        } else {
            EmptyView()
        }
    }

    var body: some View {
        let tileSize = viewModel.tileSize(from: videoSize)
        VideoRendererViewInternal(viewModel: viewModel)
            .onVideoSizeChange {
                videoSize = $0
            }
            .frame(width: tileSize.width, height: tileSize.height)
            .accessibilityIdentifier(accessibilityIdentifier)
            .overlay(alignment: .bottomLeading) {
                sourceLabelView
            }
            .overlay(alignment: .bottomTrailing) {
                videoQualityIndicatorView
            }
            .overlay {
                audioPlaybackIndicatorView
            }
            .onTapGesture {
                action?(viewModel.source)
            }
    }
}

private struct VideoRendererViewInternal: UIViewControllerRepresentable {
    class VideoViewDelegate: MCVideoViewDelegate {
        var onVideoSizeChange: ((CGSize) -> Void)?

        func didChangeVideoSize(_ size: CGSize) {
            onVideoSizeChange?(size)
        }
    }

    @ObservedObject private var viewModel: VideoRendererViewModel
    @State private var delegate: VideoViewDelegate

    init(viewModel: VideoRendererViewModel) {
        self.viewModel = viewModel

        let videoViewDelegate = VideoViewDelegate()
        self.delegate = videoViewDelegate
    }

    func makeUIViewController(context: Context) -> VideoViewController {
        VideoViewController(viewModel: viewModel, delegate: delegate)
    }

    func updateUIViewController(_ videoViewController: VideoViewController, context: Context) {
        videoViewController.updateViewModel(viewModel, delegate: delegate)
    }
}

private extension VideoRendererViewInternal {
    func onVideoSizeChange(_ perform: @escaping (CGSize) -> Void) -> some View {
        delegate.onVideoSizeChange = perform
        return self
    }
}

private class VideoViewController: UIViewController {

    private var targetView: UIView!
    private var videoView: MCSampleBufferVideoUIView!
    private var videoSize: CGSize!

    private var viewModel: VideoRendererViewModel {
        didSet {
            setupPlaybackView()
        }
    }

    weak var delegate: MCVideoViewDelegate?

    @AppConfiguration(\.enablePiP) private var enablePiP

    init(viewModel: VideoRendererViewModel, delegate: MCVideoViewDelegate) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateViewModel(_ viewModel: VideoRendererViewModel, delegate: MCVideoViewDelegate) {
        self.viewModel = viewModel
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configurePiPIfRequired()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        configurePiPIfRequired()
    }

    private func configurePiPIfRequired() {
        guard
            viewModel.isPiPView,
            enablePiP,
            PiPManager.shared.isPiPActive == false,
            videoView.frame != .zero,
            PiPManager.shared.sampleBufferDisplayLayer != videoView.sampleBufferDisplayLayer
        else { return }

        PiPManager.shared.set(pipView: videoView, targetView: targetView) { [weak self] in
            self?.setupPlaybackView()
        }
    }

    private func setupPlaybackView() {
        view.subviews.forEach { $0.removeFromSuperview() }
        let renderer = viewModel.renderer

        targetView = UIView()
        targetView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(targetView)

        videoView = MCSampleBufferVideoUIView(frame: .zero, renderer: renderer)
        videoView.translatesAutoresizingMaskIntoConstraints = false
        videoView.delegate = delegate
        view.addSubview(videoView)

        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: targetView.topAnchor),
            view.leadingAnchor.constraint(equalTo: targetView.leadingAnchor),
            targetView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            targetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            view.topAnchor.constraint(equalTo: videoView.topAnchor),
            view.leadingAnchor.constraint(equalTo: videoView.leadingAnchor),
            videoView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            videoView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}

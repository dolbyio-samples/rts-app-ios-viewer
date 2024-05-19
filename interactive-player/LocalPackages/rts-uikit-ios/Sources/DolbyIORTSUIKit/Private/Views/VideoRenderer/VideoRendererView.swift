//
//  VideoRendererView.swift
//

import DolbyIORTSCore
import DolbyIOUIKit
import MillicastSDK
import SwiftUI

struct VideoRendererView: View {
    private let viewModel: VideoRendererViewModel
    private let viewRenderer: StreamSourceViewRenderer
    private let maxWidth: CGFloat
    private let maxHeight: CGFloat
    private let contentMode: VideoRendererContentMode
    private let identifier: String
    private let action: ((StreamSource) -> Void)?
    @State var isViewVisible = false

    @ObservedObject private var themeManager = ThemeManager.shared
    @AppConfiguration(\.showDebugFeatures) var showDebugFeatures

    init(
        viewModel: VideoRendererViewModel,
        viewRenderer: StreamSourceViewRenderer,
        maxWidth: CGFloat,
        maxHeight: CGFloat,
        contentMode: VideoRendererContentMode,
        identifier: String,
        action: ((StreamSource) -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.viewRenderer = viewRenderer
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
        self.contentMode = contentMode
        self.identifier = identifier
        self.action = action
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
            SourceLabel(sourceId: viewModel.streamSource.sourceId.displayLabel)
                .accessibilityIdentifier("SourceID.\(viewModel.streamSource.sourceId.displayLabel)")
                .padding(Layout.spacing0_5x)
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private var videoQualityIndicatorView: some View {
        if showDebugFeatures, let videoQualityIndicatorText = viewModel.videoQuality.description.first?.uppercased() {
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

        VideoRendererViewInternal(viewModel: viewModel, viewRenderer: viewRenderer)
            .accessibilityIdentifier(identifier)
            .frame(width: videoSize.width, height: videoSize.height)
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
                action?(viewModel.streamSource)
            }
            .onAppear {
                isViewVisible = true
                viewModel.playVideo(on: viewRenderer)
            }
            .onDisappear {
                isViewVisible = false
                viewModel.stopVideo(on: viewRenderer)
            }
            .onChange(of: viewModel.videoQuality) { newValue in
                guard isViewVisible else { return }
                viewModel.playVideo(on: viewRenderer, quality: newValue)
            }
    }
}

private struct VideoRendererViewInternal: UIViewControllerRepresentable {
    private let viewModel: VideoRendererViewModel
    private let viewRenderer: StreamSourceViewRenderer

    init(viewModel: VideoRendererViewModel, viewRenderer: StreamSourceViewRenderer) {
        self.viewModel = viewModel
        self.viewRenderer = viewRenderer
    }

    func makeUIViewController(context: Context) -> UIViewController {
        WrappedViewController(viewModel: viewModel, viewRenderer: viewRenderer)
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        guard let wrappedView = uiViewController as? WrappedViewController else { return }

        wrappedView.updateViewModel(viewModel)
    }
}

private class WrappedViewController: UIViewController {
    private var viewModel: VideoRendererViewModel
    private let viewRenderer: StreamSourceViewRenderer

    @AppConfiguration(\.enablePiP) private var enablePiP

    init(viewModel: VideoRendererViewModel, viewRenderer: StreamSourceViewRenderer) {
        self.viewModel = viewModel
        self.viewRenderer = viewRenderer
        super.init(nibName: nil, bundle: nil)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        let playbackView = viewRenderer.playbackView
        self.view.addSubview(viewRenderer.playbackView)
        playbackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            self.view.topAnchor.constraint(equalTo: playbackView.topAnchor),
            self.view.leadingAnchor.constraint(equalTo: playbackView.leadingAnchor),
            playbackView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            playbackView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configurePiPIfRequired(force: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        configurePiPIfRequired(force: false)
    }

    func updateViewModel(_ viewModel: VideoRendererViewModel) {
        self.viewModel = viewModel
        configurePiPIfRequired(force: false)
    }

    private func configurePiPIfRequired(force: Bool) {
        guard
            viewModel.isPiPView,
            enablePiP,
            PiPManager.shared.isPiPActive == false,
            viewRenderer.playbackView.frame != .zero,
            (PiPManager.shared.pipView != viewRenderer.pipView || force)
        else { return }

        PiPManager.shared.set(pipView: viewRenderer.pipView, with: viewRenderer.playbackView)
    }
}

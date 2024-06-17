//
//  GridView.swift
//

import SwiftUI
import DolbyIORTSCore
import DolbyIOUIKit
import MillicastSDK

struct GridView: View {
    private enum Defaults {
        static let numberOfColumnsForPortrait = 1
        static let numberOfColumnsForLandscape = 2
    }

    @ObservedObject private var viewModel: GridViewModel
    private let onVideoSelection: (StreamSource) -> Void
    @State private var deviceOrientation: UIDeviceOrientation = UIDeviceOrientation.portrait

    init(
        sources: [StreamSource],
        selectedVideoSource: StreamSource,
        selectedAudioSource: StreamSource?,
        showSourceLabels: Bool,
        isShowingDetailView: Bool,
        subscriptionManager: SubscriptionManager,
        videoTracksManager: VideoTracksManager,
        onVideoSelection: @escaping (StreamSource) -> Void
    ) {
        self.onVideoSelection = onVideoSelection
        self.viewModel = GridViewModel(
            sources: sources,
            selectedVideoSource: selectedVideoSource,
            selectedAudioSource: selectedAudioSource,
            showSourceLabels: showSourceLabels,
            isShowingDetailView: isShowingDetailView,
            subscriptionManager: subscriptionManager,
            videoTracksManager: videoTracksManager
        )
    }

    var body: some View {
        GeometryReader { proxy in
            if viewModel.isShowingDetailView {
                // FIXME: With the new SDK 2.0.0 only one renderer can be attached to a video track at a time
                // Having the grid view or list view in the navigation stack cause unwanted refresh of video view's
                // As an example when the selected video view changes or when any of the settings is changed
                EmptyView()
            } else {
                let screenSize = proxy.size
                let numberOfColumns = deviceOrientation.isPortrait ? Defaults.numberOfColumnsForPortrait : Defaults.numberOfColumnsForLandscape
                let tileWidth = screenSize.width / CGFloat(numberOfColumns)
                let columns = [GridItem](repeating: GridItem(.flexible(), spacing: Layout.spacing1x), count: numberOfColumns)
                ScrollView {
                    LazyVGrid(columns: columns, alignment: .leading) {
                        ForEach(viewModel.sources, id: \.id) { source in
                            let displayLabel = source.sourceId.displayLabel
                            let preferredVideoQuality: VideoQuality = source == viewModel.selectedVideoSource ? .auto : .low
                            let isSelectedVideoSource = source == viewModel.selectedVideoSource
                            let isSelectedAudioSource = source == viewModel.selectedAudioSource
                            let viewId = "\(GridView.self).\(displayLabel)"

                            VideoRendererView(
                                source: source,
                                isSelectedVideoSource: isSelectedVideoSource,
                                isSelectedAudioSource: isSelectedAudioSource,
                                isPiPView: isSelectedVideoSource && !viewModel.isShowingDetailView,
                                showSourceLabel: viewModel.showSourceLabels,
                                showAudioIndicator: isSelectedAudioSource,
                                maxWidth: tileWidth,
                                maxHeight: .infinity,
                                accessibilityIdentifier: "GridViewVideoTile.\(source.sourceId.displayLabel)",
                                preferredVideoQuality: preferredVideoQuality,
                                subscriptionManager: viewModel.subscriptionManager,
                                videoTracksManager: viewModel.videoTracksManager,
                                action: { source in
                                    onVideoSelection(source)
                                }
                            )
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
                            .onAppear {
                                GridViewModel.logger.debug("♼ Grid view: Video view appear for \(source.sourceId)")
                                Task {
                                    await viewModel.videoTracksManager.enableTrack(for: source, with: preferredVideoQuality, on: viewId)
                                }
                            }
                            .onDisappear {
                                GridViewModel.logger.debug("♼ Grid view: Video view disappear for \(source.sourceId)")
                                Task {
                                    await viewModel.videoTracksManager.disableTrack(for: source, on: viewId)
                                }
                            }
                            .id(source.id)
                        }
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
                }
            }
        }
        .onRotate { newOrientation in
            if !newOrientation.isFlat && newOrientation.isValidInterfaceOrientation {
                deviceOrientation = newOrientation
            }
        }
    }
}

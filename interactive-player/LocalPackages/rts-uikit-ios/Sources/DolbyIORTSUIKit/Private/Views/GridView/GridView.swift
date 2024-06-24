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

    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var rendererRegistry: RendererRegistry = RendererRegistry()

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
            let screenSize = proxy.size
            let numberOfColumns = sizeClass == .compact ? Defaults.numberOfColumnsForPortrait : Defaults.numberOfColumnsForLandscape
            let tileWidth = screenSize.width / CGFloat(numberOfColumns)
            let columns = [GridItem](repeating: GridItem(.flexible(), spacing: Layout.spacing1x), count: numberOfColumns)
            ScrollView {
                LazyVGrid(columns: columns, alignment: .leading) {
                    ForEach(viewModel.sources, id: \.id) { source in
                        VideoRendererView(
                            source: source,
                            isSelectedVideoSource: source == viewModel.selectedVideoSource,
                            isSelectedAudioSource: source == viewModel.selectedAudioSource,
                            isPiPView: source == viewModel.selectedVideoSource && !viewModel.isShowingDetailView,
                            showSourceLabel: viewModel.showSourceLabels,
                            showAudioIndicator: source == viewModel.selectedAudioSource,
                            maxWidth: tileWidth,
                            maxHeight: .infinity,
                            accessibilityIdentifier: "GridViewVideoTile.\(source.sourceId.displayLabel)",
                            preferredVideoQuality: source == viewModel.selectedVideoSource ? .auto : .low,
                            subscriptionManager: viewModel.subscriptionManager,
                            rendererRegistry: rendererRegistry,
                            pipRendererRegistry: viewModel.pipRendererRegistry,
                            videoTracksManager: viewModel.videoTracksManager,
                            action: { source in
                                onVideoSelection(source)
                            }
                        )
                        .id(source.id)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
            }
        }
    }
}

//
//  ListView.swift
//

import SwiftUI
import DolbyIORTSCore
import DolbyIOUIKit
import MillicastSDK

struct ListView: View {
    private enum Constants {
        static let tileSpacing: CGFloat = Layout.spacing1x
    }

    @ObservedObject private var viewModel: ListViewModel
    private let onPrimaryVideoSelection: (StreamSource) -> Void
    private let onSecondaryVideoSelection: (StreamSource) -> Void

    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var portraitRendererRegistry: RendererRegistry = RendererRegistry()
    @State private var landscapeRendererRegistry: RendererRegistry = RendererRegistry()

    init(
        sources: [StreamSource],
        selectedVideoSource: StreamSource,
        selectedAudioSource: StreamSource?,
        showSourceLabels: Bool,
        isShowingDetailView: Bool,
        mainTilePreferredVideoQuality: VideoQuality,
        subscriptionManager: SubscriptionManager,
        videoTracksManager: VideoTracksManager,
        onPrimaryVideoSelection: @escaping (StreamSource) -> Void,
        onSecondaryVideoSelection: @escaping (StreamSource) -> Void
    ) {
        self.onPrimaryVideoSelection = onPrimaryVideoSelection
        self.onSecondaryVideoSelection = onSecondaryVideoSelection
        self.viewModel = ListViewModel(
            sources: sources,
            selectedVideoSource: selectedVideoSource,
            selectedAudioSource: selectedAudioSource,
            showSourceLabels: showSourceLabels,
            isShowingDetailView: isShowingDetailView,
            mainTilePreferredVideoQuality: mainTilePreferredVideoQuality,
            videoTracksManager: videoTracksManager
        )
    }

    private func gridItems(for screenWidth: CGFloat) -> [GridItem] {
        Array(repeating: GridItem(.fixed(secondaryTileWidth(for: screenWidth)), spacing: Constants.tileSpacing), count: numberOfColumns)
    }

    private var numberOfColumns: Int {
        sizeClass == .compact ? 2 : 1
    }

    private var pinnedViews: PinnedScrollableViews {
        sizeClass == .compact ? [.sectionHeaders] : []
    }

    @ViewBuilder
    private func primaryView(for screenSize: CGSize) -> some View {
        let selectedVideoSource = viewModel.selectedVideoSource
        let tileWidth = sizeClass == .compact ?
        screenSize.width - Constants.tileSpacing :
        screenSize.width * 0.75 - Constants.tileSpacing

        VideoRendererView(
            source: selectedVideoSource,
            isSelectedVideoSource: true,
            isSelectedAudioSource: selectedVideoSource == viewModel.selectedAudioSource,
            isPiPView: viewModel.isShowingDetailView,
            showSourceLabel: viewModel.showSourceLabels,
            showAudioIndicator: viewModel.selectedAudioSource == selectedVideoSource,
            maxWidth: tileWidth,
            maxHeight: .infinity,
            accessibilityIdentifier: "PrimaryVideoTile.\(selectedVideoSource.sourceId.displayLabel)",
            preferredVideoQuality: viewModel.mainTilePreferredVideoQuality,
            subscriptionManager: viewModel.subscriptionManager,
            rendererRegistry: sizeClass == .compact ? portraitRendererRegistry : landscapeRendererRegistry,
            pipRendererRegistry: viewModel.pipRendererRegistry,
            videoTracksManager: viewModel.videoTracksManager,
            action: { source in
                onPrimaryVideoSelection(source)
            }
        )
        .id(selectedVideoSource.id)
    }

    private func secondaryTileWidth(for screenWidth: CGFloat) -> CGFloat {
        sizeClass == .compact ? screenWidth / 2 - Constants.tileSpacing : screenWidth * 0.25
    }

    var body: some View {
        GeometryReader { proxy in
            DynamicStack(spacing: Constants.tileSpacing) {
                Spacer()
                    .frame(width: Layout.spacing0x, height: Layout.spacing0x)

                primaryView(for: proxy.size)

                ScrollView {
                    LazyVGrid(columns: gridItems(for: proxy.size.width)) {
                        Section(content: {
                            ForEach(viewModel.secondarySources, id: \.id) { source in
                                VideoRendererView(
                                    source: source,
                                    isSelectedVideoSource: false,
                                    isSelectedAudioSource: source == viewModel.selectedAudioSource,
                                    isPiPView: false,
                                    showSourceLabel: viewModel.showSourceLabels,
                                    showAudioIndicator: viewModel.selectedAudioSource == source,
                                    maxWidth: secondaryTileWidth(for: proxy.size.width),
                                    maxHeight: .infinity,
                                    accessibilityIdentifier: "SecondaryVideoTile.\(source.sourceId.displayLabel)",
                                    preferredVideoQuality: .low,
                                    subscriptionManager: viewModel.subscriptionManager,
                                    rendererRegistry: sizeClass == .compact ? portraitRendererRegistry : landscapeRendererRegistry,
                                    pipRendererRegistry: viewModel.pipRendererRegistry,
                                    videoTracksManager: viewModel.videoTracksManager,
                                    action: { source in
                                        onSecondaryVideoSelection(source)
                                    }
                                )
                                .id(source.id)
                            }
                        })
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}

struct DynamicStack<Content: View>: View {
    let horizontalAlignment = HorizontalAlignment.center
    let verticalAlignment = VerticalAlignment.center
    let spacing: CGFloat?
    @ViewBuilder var content: () -> Content
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        switch sizeClass {
        case .regular:
            hStack
        case .compact, .none:
            vStack
        @unknown default:
            vStack
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
    }

    var vStack: some View {
        VStack(
            alignment: horizontalAlignment,
            spacing: spacing,
            content: content
        )
    }
}

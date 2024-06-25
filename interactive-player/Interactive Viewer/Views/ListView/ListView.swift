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
            subscriptionManager: subscriptionManager,
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
        let displayLabel = selectedVideoSource.sourceId.displayLabel
        let preferredVideoQuality: VideoQuality = selectedVideoSource == viewModel.selectedVideoSource ? .auto : .low
        let isSelectedVideoSource = true
        let isSelectedAudioSource = selectedVideoSource == viewModel.selectedAudioSource
        let viewId = sizeClass == .compact ? "\(ListView.self).Primary.Portrait.\(displayLabel)" : "\(ListView.self).Primary.Landscape.\(displayLabel)"

        VideoRendererView(
            source: selectedVideoSource,
            isSelectedVideoSource: isSelectedVideoSource,
            isSelectedAudioSource: isSelectedAudioSource,
            isPiPView: viewModel.isShowingDetailView,
            showSourceLabel: viewModel.showSourceLabels,
            showAudioIndicator: isSelectedAudioSource,
            maxWidth: tileWidth,
            maxHeight: .infinity,
            accessibilityIdentifier: "PrimaryVideoTile.\(displayLabel)",
            preferredVideoQuality: viewModel.mainTilePreferredVideoQuality,
            subscriptionManager: viewModel.subscriptionManager,
            videoTracksManager: viewModel.videoTracksManager,
            action: { source in
                onPrimaryVideoSelection(source)
            }
        )
        .onAppear {
            ListViewModel.logger.debug("♼ List view: Primary view appear for \(selectedVideoSource.sourceId)")
            Task {
                await viewModel.videoTracksManager.enableTrack(for: selectedVideoSource, with: preferredVideoQuality, on: viewId)
            }
        }
        .onDisappear {
            ListViewModel.logger.debug("♼ List view: Primary view disappear for \(selectedVideoSource.sourceId)")
            Task {
                await viewModel.videoTracksManager.disableTrack(for: selectedVideoSource, on: viewId)
            }
        }
        .id(selectedVideoSource.id)
    }

    private func secondaryTileWidth(for screenWidth: CGFloat) -> CGFloat {
        sizeClass == .compact ? screenWidth / 2 - Constants.tileSpacing : screenWidth * 0.25
    }

    var body: some View {
        GeometryReader { proxy in
            if viewModel.isShowingDetailView {
                // FIXME: With the new SDK 2.0.0 only one renderer can be attached to a video track at a time
                // Having the grid view or list view in the navigation stack cause unwanted refresh of video view's
                // As an example when the selected video view changes or when any of the settings is changed
                EmptyView()
            } else {
                DynamicStack(spacing: Constants.tileSpacing) {
                    Spacer()
                        .frame(width: Layout.spacing0x, height: Layout.spacing0x)

                    primaryView(for: proxy.size)

                    ScrollView {
                        LazyVGrid(columns: gridItems(for: proxy.size.width)) {
                            Section(content: {
                                ForEach(viewModel.secondarySources, id: \.id) { source in
                                    let displayLabel = source.sourceId.displayLabel
                                    let preferredVideoQuality: VideoQuality = .low
                                    let isSelectedVideoSource = false
                                    let isSelectedAudioSource = source == viewModel.selectedAudioSource
                                    let viewId = sizeClass == .compact ? "\(ListView.self).Secondary.Portrait.\(displayLabel)" : "\(ListView.self).Secondary.Landscape.\(displayLabel)"

                                    VideoRendererView(
                                        source: source,
                                        isSelectedVideoSource: isSelectedVideoSource,
                                        isSelectedAudioSource: isSelectedAudioSource,
                                        isPiPView: isSelectedVideoSource,
                                        showSourceLabel: viewModel.showSourceLabels,
                                        showAudioIndicator: isSelectedAudioSource,
                                        maxWidth: secondaryTileWidth(for: proxy.size.width),
                                        maxHeight: .infinity,
                                        accessibilityIdentifier: "SecondaryVideoTile.\(displayLabel)",
                                        preferredVideoQuality: preferredVideoQuality,
                                        subscriptionManager: viewModel.subscriptionManager,
                                        videoTracksManager: viewModel.videoTracksManager,
                                        action: { source in
                                            onSecondaryVideoSelection(source)
                                        }
                                    )
                                    .onAppear {
                                        guard !viewModel.isShowingDetailView else { return }
                                        ListViewModel.logger.debug("♼ List view: Secondary view appear for \(source.sourceId)")
                                        Task {
                                            await viewModel.videoTracksManager.enableTrack(for: source, with: preferredVideoQuality, on: viewId)
                                        }
                                    }
                                    .onDisappear {
                                        ListViewModel.logger.debug("♼ List view: Secondary view disappear for \(source.sourceId)")
                                        Task {
                                            await viewModel.videoTracksManager.disableTrack(for: source, on: viewId)
                                        }
                                    }
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

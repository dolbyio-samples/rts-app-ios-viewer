//
//  ListView.swift
//

import SwiftUI
import RTSCore
import DolbyIOUIKit
import MillicastSDK

struct ListView: View {
    private enum Constants {
        static let tileSpacing: CGFloat = Layout.spacing1x
    }

    private let viewModel: ListViewModel
    private let onPrimaryVideoSelection: (StreamSource) -> Void
    private let onSecondaryVideoSelection: (StreamSource) -> Void
    @State private var deviceOrientation: UIDeviceOrientation = UIDeviceOrientation.portrait

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
        deviceOrientation.isPortrait ? 2 : 1
    }

    @ViewBuilder
    private func primaryView(for screenSize: CGSize) -> some View {
        let selectedVideoSource = viewModel.selectedVideoSource
        let tileWidth = deviceOrientation.isPortrait ? screenSize.width - Constants.tileSpacing : screenSize.width * 0.75 - Constants.tileSpacing
        let displayLabel = selectedVideoSource.sourceId.displayLabel
        let preferredVideoQuality: VideoQuality = viewModel.mainTilePreferredVideoQuality
        let isSelectedVideoSource = true
        let isSelectedAudioSource = selectedVideoSource == viewModel.selectedAudioSource
        let viewId = deviceOrientation.isPortrait ? "\(ListView.self).Primary.Portrait.\(displayLabel)" : "\(ListView.self).Primary.Landscape.\(displayLabel)"

        VideoRendererView(
            source: selectedVideoSource,
            isSelectedVideoSource: isSelectedVideoSource,
            isSelectedAudioSource: isSelectedAudioSource,
            isPiPView: !viewModel.isShowingDetailView,
            showSourceLabel: viewModel.showSourceLabels,
            showAudioIndicator: isSelectedAudioSource,
            maxWidth: tileWidth,
            maxHeight: screenSize.height,
            accessibilityIdentifier: "PrimaryVideoTile.\(displayLabel)",
            preferredVideoQuality: viewModel.mainTilePreferredVideoQuality,
            subscriptionManager: viewModel.subscriptionManager,
            videoTracksManager: viewModel.videoTracksManager,
            action: { source in
                onPrimaryVideoSelection(source)
            }
        )
        .onAppear {
            ListViewModel.logger.debug("♼ List view: Primary view appear for \(selectedVideoSource.sourceId) - \(viewId)")
            Task {
                await viewModel.videoTracksManager.enableTrack(for: selectedVideoSource, with: preferredVideoQuality, on: viewId)
            }
        }
        .onDisappear {
            ListViewModel.logger.debug("♼ List view: Primary view disappear for \(selectedVideoSource.sourceId) - \(viewId)")
            Task {
                await viewModel.videoTracksManager.disableTrack(for: selectedVideoSource, on: viewId)
            }
        }
        .id(selectedVideoSource.id)
    }

    private func gridOfSecondaryTiles(for screenSize: CGSize) -> some View {
        ScrollView {
            LazyVGrid(columns: gridItems(for: screenSize.width)) {
                ForEach(viewModel.secondarySources, id: \.id) { source in
                    let displayLabel = source.sourceId.displayLabel
                    let preferredVideoQuality: VideoQuality = .low
                    let isSelectedVideoSource = false
                    let isSelectedAudioSource = source == viewModel.selectedAudioSource
                    let viewId = deviceOrientation.isPortrait ? "\(ListView.self).Secondary.Portrait.\(displayLabel)" : "\(ListView.self).Secondary.Landscape.\(displayLabel)"

                    VideoRendererView(
                        source: source,
                        isSelectedVideoSource: isSelectedVideoSource,
                        isSelectedAudioSource: isSelectedAudioSource,
                        isPiPView: isSelectedVideoSource,
                        showSourceLabel: viewModel.showSourceLabels,
                        showAudioIndicator: isSelectedAudioSource,
                        maxWidth: secondaryTileWidth(for: screenSize.width),
                        maxHeight: screenSize.height,
                        accessibilityIdentifier: "SecondaryVideoTile.\(displayLabel)",
                        preferredVideoQuality: preferredVideoQuality,
                        subscriptionManager: viewModel.subscriptionManager,
                        videoTracksManager: viewModel.videoTracksManager,
                        action: { source in
                            onSecondaryVideoSelection(source)
                        }
                    )
                    .onAppear {
                        ListViewModel.logger.debug("♼ List view: Secondary view appear for \(source.sourceId) - \(viewId)")
                        Task {
                            await viewModel.videoTracksManager.enableTrack(for: source, with: preferredVideoQuality, on: viewId)
                        }
                    }
                    .onDisappear {
                        ListViewModel.logger.debug("♼ List view: Secondary view disappear for \(source.sourceId) - \(viewId)")
                        Task {
                            await viewModel.videoTracksManager.disableTrack(for: source, on: viewId)
                        }
                    }
                }
            }
        }
        .frame(width: deviceOrientation.isPortrait ? screenSize.width : screenSize.width * 0.25)
    }

    private func secondaryTileWidth(for screenWidth: CGFloat) -> CGFloat {
        deviceOrientation.isPortrait ? screenWidth / 2 - Constants.tileSpacing : screenWidth * 0.25
    }

    var body: some View {
        GeometryReader { proxy in
            if viewModel.isShowingDetailView {
                // FIXME: With the new SDK 2.0.0 only one renderer can be attached to a video track at a time
                // Having the grid view or list view in the navigation stack cause unwanted refresh of video view's
                // As an example when the selected video view changes or when any of the settings is changed
                EmptyView()
            } else {
                if deviceOrientation.isPortrait {
                    VStack(spacing: Constants.tileSpacing) {
                        primaryView(for: proxy.size)
                            .frame(width: proxy.size.width)
                        gridOfSecondaryTiles(for: proxy.size)
                    }
                } else {
                    HStack(spacing: Constants.tileSpacing) {
                        primaryView(for: proxy.size)
                            .frame(height: proxy.size.height)
                        gridOfSecondaryTiles(for: proxy.size)
                    }
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

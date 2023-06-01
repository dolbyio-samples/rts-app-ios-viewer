//
//  ListView.swift
//

import SwiftUI
import DolbyIORTSCore
import DolbyIOUIKit

struct ListView: View {
    private enum Defaults {
        static let maximumNumberOfTilesRatio: CGFloat = 1 / 3
        static let defaultThumbnailSizeRatio: CGFloat = 1 / 2
        static let horizontalGridThumbnailSizeRatio: CGFloat = 1 / 4
        static let sideListThumbnailSizeRatio: CGFloat = 1 / 4
        static let sideMainViewSizeRatio: CGFloat = 3 / 4
    }

    /**
     ListViewLayout describes the layout modes for the ListView:
     leadingVertical - main tile on left, vertically scrollable 1 column grid on the right
     trailingVertical - vertically scrollable 1 column grid on left, main tile on the right
     bottomHorizontal - horizontally scrollable grid on top, main tile below
     bottomVertical - vertically scrollable grid on top, main tile below
     topHorizontal - main tile on top, horizontally scrollable grid below
     topVertical - main tile on top, vertically scrollable grid below
     */
    enum ListViewLayout {
        case leadingVertical, trailingVertical, bottomHorizontal(rows: Int = 2), bottomVertical(columns: Int = 2), topHorizontal(rows: Int = 2), topVertical(columns: Int = 2)
    }

    @ObservedObject private var viewModel: StreamViewModel
    private var onMainSourceSelection: () -> Void

    private let layout: ListViewLayout

    init(viewModel: StreamViewModel, onMainSourceSelection: @escaping () -> Void, layout: ListViewLayout = .topVertical()) {
        self.viewModel = viewModel
        self.onMainSourceSelection = onMainSourceSelection

        self.layout = layout
    }

    @ViewBuilder
    private var audioPlaybackIndicatorView: some View {
        Rectangle()
            .stroke(
                Color(uiColor: UIColor.Primary.neonPurple400),
                lineWidth: Layout.border2x
            )
    }

    var body: some View {
        GeometryReader { proxy in
            if viewModel.isStreamActive {
                let screenSize = proxy.size
                switch layout {
                case .topVertical(columns: let columns):
                    topVerticalLayout(screenSize, columns)
                case .topHorizontal(rows: let rows):
                    topHorizontalLayout(screenSize, rows)
                case .bottomVertical(columns: let columns):
                    bottomVerticalLayout(screenSize, columns)
                case .bottomHorizontal(rows: let rows):
                    bottomHorizontalLayout(screenSize, rows)
                case .leadingVertical:
                    leadingVerticalLayout(screenSize)
                case .trailingVertical:
                    trailingVerticalLayout(screenSize)
                }
            }
        }
    }

    private func topVerticalLayout(_ screenSize: CGSize, _ columnsCount: Int) -> some View {
        let columns = [GridItem](repeating: GridItem(.flexible(), spacing: Layout.spacing1x), count: columnsCount)
        return ScrollView {
            LazyVGrid(columns: columns, alignment: .leading, pinnedViews: [.sectionHeaders]) {
                Section(
                    header: HStack {
                        if let source = viewModel.selectedVideoSource, let mainViewProvider = viewModel.mainViewProvider(for: source) {
                            let maxAllowedMainVideoSize = CGSize(width: screenSize.width, height: screenSize.height * Defaults.maximumNumberOfTilesRatio)
                            mainView(screenSize, mainViewProvider, source, maxAllowedMainVideoSize)
                        }
                    }
                        .clipped()
                ) {
                    gridVertical(
                        screenSize: screenSize,
                        thumbnailSizeRatio: thumbnailRatioForColumnCount(columnCount: columnsCount)
                    )
                }
            }
            Spacer()
        }
    }

    private func topHorizontalLayout(_ screenSize: CGSize, _ rowsCount: Int) -> some View {
        VStack {
            let maxAllowedMainVideoSize = CGSize(width: screenSize.width, height: screenSize.height * Defaults.maximumNumberOfTilesRatio)
            if let source = viewModel.selectedVideoSource, let mainViewProvider = viewModel.mainViewProvider(for: source) {
                mainView(screenSize, mainViewProvider, source, maxAllowedMainVideoSize)
            }
            ScrollView(.horizontal) {
                let availableRowHeight = horizontalGridTileAvailableHeight(screenSize: screenSize, maxAllowedMainVideoSize: maxAllowedMainVideoSize, rowsCount: rowsCount)
                let rows = [GridItem](repeating: GridItem(.fixed(CGFloat(availableRowHeight)), spacing: Layout.spacing1x), count: rowsCount)
                LazyHGrid(rows: rows, alignment: .top, spacing: Layout.spacing1x) {
                    gridHorizontal(availableHeight: availableRowHeight)
                }
            }
        }
    }

    private func bottomVerticalLayout(_ screenSize: CGSize, _ columnsCount: Int) -> some View {
        ScrollView {
            let columns = [GridItem](repeating: GridItem(.flexible(), spacing: Layout.spacing1x), count: columnsCount)
            LazyVGrid(columns: columns, alignment: .leading, pinnedViews: [.sectionFooters]) {
                Section(
                    footer: HStack {
                        if let source = viewModel.selectedVideoSource, let mainViewProvider = viewModel.mainViewProvider(for: source) {
                            let maxAllowedMainVideoSize = CGSize(width: screenSize.width, height: screenSize.height * Defaults.maximumNumberOfTilesRatio)
                            mainView(screenSize, mainViewProvider, source, maxAllowedMainVideoSize)
                        }
                    }
                        .clipped()
                ) {
                    gridVertical(
                        screenSize: screenSize,
                        thumbnailSizeRatio: thumbnailRatioForColumnCount(columnCount: columnsCount)
                    )
                }
            }
        }
    }

    private func bottomHorizontalLayout(_ screenSize: CGSize, _ rowsCount: Int) -> some View {
        VStack {
            let maxAllowedMainVideoSize = CGSize(width: screenSize.width, height: screenSize.height * Defaults.maximumNumberOfTilesRatio)
            ScrollView(.horizontal) {
                let availableRowHeight = horizontalGridTileAvailableHeight(screenSize: screenSize, maxAllowedMainVideoSize: maxAllowedMainVideoSize, rowsCount: rowsCount)
                let rows = [GridItem](repeating: GridItem(.fixed(CGFloat(availableRowHeight)), spacing: Layout.spacing1x), count: rowsCount)
                LazyHGrid(rows: rows, alignment: .top, spacing: Layout.spacing1x) {
                    gridHorizontal(availableHeight: availableRowHeight)
                }.frame(height: availableRowHeight * CGFloat(rowsCount))
            }
            if let source = viewModel.selectedVideoSource, let mainViewProvider = viewModel.mainViewProvider(for: source) {
                mainView(screenSize, mainViewProvider, source, maxAllowedMainVideoSize)
            }
            Spacer()
        }
    }

    private func leadingVerticalLayout(_ screenSize: CGSize) -> some View {
        let columns = [GridItem](repeating: GridItem(.flexible(), spacing: Layout.spacing1x), count: 1)
        return HStack {
            if let source = viewModel.selectedVideoSource, let mainViewProvider = viewModel.mainViewProvider(for: source) {
                HStack(alignment: .top) {
                    let maxAllowedMainVideoSize = CGSize(width: screenSize.width * Defaults.sideMainViewSizeRatio, height: screenSize.height)
                    mainView(screenSize, mainViewProvider, source, maxAllowedMainVideoSize)
                    ScrollView {
                        LazyVGrid(columns: columns) {
                            gridVertical(
                                screenSize: screenSize,
                                thumbnailSizeRatio: Defaults.sideListThumbnailSizeRatio
                            )
                        }
                    }.frame(width: CGFloat(screenSize.width) * Defaults.sideListThumbnailSizeRatio)
                }
            }
        }
    }

    private func trailingVerticalLayout(_ screenSize: CGSize) -> some View {
        let columns = [GridItem](repeating: GridItem(.flexible(), spacing: Layout.spacing1x), count: 1)
        return HStack {
            if let source = viewModel.selectedVideoSource, let mainViewProvider = viewModel.mainViewProvider(for: source) {
                HStack(alignment: .top) {
                    ScrollView {
                        LazyVGrid(columns: columns) {
                            gridVertical(
                                screenSize: screenSize,
                                thumbnailSizeRatio: Defaults.sideListThumbnailSizeRatio
                            )
                        }
                    }.frame(width: CGFloat(screenSize.width) * Defaults.sideListThumbnailSizeRatio)
                    let maxAllowedMainVideoSize = CGSize(width: screenSize.width * Defaults.sideMainViewSizeRatio, height: screenSize.height)
                    mainView(screenSize, mainViewProvider, source, maxAllowedMainVideoSize)
                }
            }
        }
    }

    private func maxAllowedMainVideoWidth(screenSize: CGSize) -> CGFloat {
        return screenSize.width
    }

    private func maxAllowedSideMainVideoWidth(screenSize: CGSize) -> CGFloat {
        return screenSize.width * Defaults.sideMainViewSizeRatio
    }

    private func maxAllowedMainVideoHeight(screenSize: CGSize) -> CGFloat {
        return screenSize.height * Defaults.maximumNumberOfTilesRatio
    }

    private func mainView(_ screenSize: CGSize, _ mainViewProvider: SourceViewProviding, _ source: StreamSource, _ maxAllowedMainVideoSize: CGSize) -> some View {
        let videoSize = mainViewProvider.videoViewDisplaySize(
            forAvailableScreenWidth: maxAllowedMainVideoSize.width,
            availableScreenHeight: maxAllowedMainVideoSize.height
        )
        return VideoRendererView(viewProvider: mainViewProvider)
            .frame(width: videoSize.width, height: videoSize.height)
            .overlay(
                viewModel.selectedAudioSource == source ? audioPlaybackIndicatorView : nil
            )
            .onAppear {
                viewModel.playVideo(for: source)
            }
            .onTapGesture {
                onMainSourceSelection()
            }
    }

    private func gridVertical(screenSize: CGSize, thumbnailSizeRatio: CGFloat) -> ForEach<[StreamSource], UUID, HStack<(some View)?>> {
        return ForEach(viewModel.otherSources, id: \.id) { subVideosource in
            let maxAllowedSubVideoWidth = screenSize.width * thumbnailSizeRatio
            let maxAllowedSubVideoHeight = screenSize.height * thumbnailSizeRatio
            HStack {
                if let subViewProvider = viewModel.subViewProvider(for: subVideosource) {
                    let videoSize = subViewProvider.videoViewDisplaySize(
                        forAvailableScreenWidth: maxAllowedSubVideoWidth,
                        availableScreenHeight: maxAllowedSubVideoHeight
                    )
                    VideoRendererView(viewProvider: subViewProvider)
                        .frame(width: videoSize.width, height: videoSize.height)
                        .overlay(
                            viewModel.selectedAudioSource == subVideosource ? audioPlaybackIndicatorView : nil
                        )
                        .onTapGesture {
                            viewModel.selectVideoSource(subVideosource)
                        }
                        .onAppear {
                            viewModel.playVideo(for: subVideosource)
                        }
                }
            }
        }
    }

    private func gridHorizontal(availableHeight: CGFloat) -> ForEach<[StreamSource], UUID, HStack<(some View)?>> {
        return ForEach(viewModel.otherSources, id: \.id) { subVideosource in
            HStack {
                if let subViewProvider = viewModel.subViewProvider(for: subVideosource) {
                    let videoSize = subViewProvider.videoViewDisplaySize(
                        forAvailableScreenWidth: .infinity,
                        availableScreenHeight: availableHeight
                    )
                    VideoRendererView(viewProvider: subViewProvider)
                        .frame(width: videoSize.width, height: videoSize.height)
                        .overlay(
                            viewModel.selectedAudioSource == subVideosource ? audioPlaybackIndicatorView : nil
                        )
                        .onTapGesture {
                            viewModel.selectVideoSource(subVideosource)
                        }
                        .onAppear {
                            viewModel.playVideo(for: subVideosource)
                        }
                }
            }
        }
    }

    func thumbnailRatioForColumnCount(columnCount: Int) -> CGFloat {
        return columnCount <= 2 ? Defaults.defaultThumbnailSizeRatio : 1 / CGFloat(columnCount)
    }

    func horizontalGridTileAvailableHeight(screenSize: CGSize, maxAllowedMainVideoSize: CGSize, rowsCount: Int) -> CGFloat {
        return (screenSize.height - maxAllowedMainVideoSize.height) * (rowsCount <= 4 ? Defaults.horizontalGridThumbnailSizeRatio : 1 / CGFloat(rowsCount))
    }
}

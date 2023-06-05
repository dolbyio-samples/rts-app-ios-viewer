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
        static let defaultCellCount = 2
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
        case leadingVertical
        case trailingVertical
        case bottomHorizontal(rows: Int = Defaults.defaultCellCount)
        case bottomVertical(columns: Int = Defaults.defaultCellCount)
        case topHorizontal(rows: Int = Defaults.defaultCellCount)
        case topVertical(columns: Int = Defaults.defaultCellCount)
    }

    @ObservedObject private var viewModel: StreamViewModel

    @State private var deviceOrientation: UIDeviceOrientation = UIDeviceOrientation.unknown

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

    @ViewBuilder
    private func showLabel(for source: StreamSource) -> some View {
        if viewModel.showSourceLabels {
            SourceLabel(sourceId: source.sourceId.label).padding(5)
        }
    }

    var body: some View {
        GeometryReader { proxy in
            VStack {
                if viewModel.isStreamActive {
                    let screenSize = proxy.size
                    switch layout {
                    case .topVertical(columns: let columns):
                        if deviceOrientation.isPortrait {
                            topVerticalLayout(screenSize, columns)
                        } else {
                            leadingVerticalLayout(screenSize)
                        }
                    case .topHorizontal(rows: let rows):
                        if deviceOrientation.isPortrait {
                            topHorizontalLayout(screenSize, rows)
                        } else {
                            leadingVerticalLayout(screenSize)
                        }
                    case .bottomVertical(columns: let columns):
                        if deviceOrientation.isPortrait {
                            bottomVerticalLayout(screenSize, columns)
                        } else {
                            trailingVerticalLayout(screenSize)
                        }
                    case .bottomHorizontal(rows: let rows):
                        if deviceOrientation.isPortrait {
                            bottomHorizontalLayout(screenSize, rows)
                        } else {
                            trailingVerticalLayout(screenSize)
                        }
                    case .leadingVertical:
                        if deviceOrientation.isPortrait {
                            topVerticalLayout(screenSize, Defaults.defaultCellCount)
                        } else {
                            leadingVerticalLayout(screenSize)
                        }
                    case .trailingVertical:
                        if deviceOrientation.isPortrait {
                            bottomVerticalLayout(screenSize, Defaults.defaultCellCount)
                        } else {
                            trailingVerticalLayout(screenSize)
                        }
                    }
                }
            }.onRotate { newOrientation in
                if !newOrientation.isFlat {
                    deviceOrientation = newOrientation
                }
            }
        }
        .overlay(alignment: .topLeading) {
            LiveIndicatorView().padding(5)
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
                    }.clipped()
                ) {
                    gridVertical(screenSize, thumbnailRatioForColumnCount(columnCount: columnsCount))
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
                gridHorizontal(availableHeight: availableRowHeight, rowsCount: rowsCount)
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
                    }.clipped()
                ) {
                    gridVertical(screenSize, thumbnailRatioForColumnCount(columnCount: columnsCount))
                }
            }
        }
    }

    private func bottomHorizontalLayout(_ screenSize: CGSize, _ rowsCount: Int) -> some View {
        VStack {
            let maxAllowedMainVideoSize = CGSize(width: screenSize.width, height: screenSize.height * Defaults.maximumNumberOfTilesRatio)
            ScrollView(.horizontal) {
                let availableRowHeight = horizontalGridTileAvailableHeight(screenSize: screenSize, maxAllowedMainVideoSize: maxAllowedMainVideoSize, rowsCount: rowsCount)
                gridHorizontal(availableHeight: availableRowHeight, rowsCount: rowsCount).frame(height: availableRowHeight * CGFloat(rowsCount))
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
                        LazyVGrid(columns: columns, alignment: .leading) {
                            gridVertical(screenSize, Defaults.sideListThumbnailSizeRatio)
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
                        LazyVGrid(columns: columns, alignment: .trailing) {
                            gridVertical(screenSize, Defaults.sideListThumbnailSizeRatio)
                        }
                    }.frame(width: CGFloat(screenSize.width) * Defaults.sideListThumbnailSizeRatio)
                    let maxAllowedMainVideoSize = CGSize(width: screenSize.width * Defaults.sideMainViewSizeRatio, height: screenSize.height)
                    mainView(screenSize, mainViewProvider, source, maxAllowedMainVideoSize)
                }
            }
        }
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
            .overlay(alignment: .bottomLeading) {
                showLabel(for: source)
            }
    }

    private func gridVertical(_ screenSize: CGSize, _ thumbnailSizeRatio: CGFloat) -> ForEach<[StreamSource], UUID, HStack<(some View)?>> {
        return ForEach(viewModel.otherSources, id: \.id) { subVideosource in
            let maxAllowedSubVideoWidth = screenSize.width * thumbnailSizeRatio
            let maxAllowedSubVideoHeight = screenSize.height * thumbnailSizeRatio
            HStack {
                if let subViewProvider = viewModel.subViewProvider(for: subVideosource) {
                    let videoSize = subViewProvider.videoViewDisplaySize(
                        forAvailableScreenWidth: maxAllowedSubVideoWidth,
                        availableScreenHeight: maxAllowedSubVideoHeight
                    )
                    subView(subVideosource, subViewProvider, videoSize)
                }
            }
        }
    }

    private func gridHorizontal(availableHeight: CGFloat, rowsCount: Int) -> LazyHGrid<ForEach<[StreamSource], UUID, HStack<(some View)?>>> {
        let rows = [GridItem](repeating: GridItem(.fixed(CGFloat(availableHeight)), spacing: Layout.spacing1x), count: rowsCount)
        return LazyHGrid(rows: rows, alignment: .top, spacing: Layout.spacing1x) {
            ForEach(viewModel.otherSources, id: \.id) { subVideosource in
                HStack {
                    if let subViewProvider = viewModel.subViewProvider(for: subVideosource) {
                        let videoSize = subViewProvider.videoViewDisplaySize(
                            forAvailableScreenWidth: .infinity,
                            availableScreenHeight: availableHeight
                        )
                        subView(subVideosource, subViewProvider, videoSize)
                    }
                }
            }
        }
    }

    fileprivate func subView(_ subVideosource: StreamSource, _ subViewProvider: SourceViewProviding, _ videoSize: CGSize) -> some View {
        return VideoRendererView(viewProvider: subViewProvider)
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
            .overlay(alignment: .bottomLeading) {
                showLabel(for: subVideosource)
            }
    }

    func thumbnailRatioForColumnCount(columnCount: Int) -> CGFloat {
        return columnCount <= 2 ? Defaults.defaultThumbnailSizeRatio : 1 / CGFloat(columnCount)
    }

    func horizontalGridTileAvailableHeight(screenSize: CGSize, maxAllowedMainVideoSize: CGSize, rowsCount: Int) -> CGFloat {
        return (screenSize.height - maxAllowedMainVideoSize.height) * (rowsCount <= 4 ? Defaults.horizontalGridThumbnailSizeRatio : 1 / CGFloat(rowsCount))
    }
}

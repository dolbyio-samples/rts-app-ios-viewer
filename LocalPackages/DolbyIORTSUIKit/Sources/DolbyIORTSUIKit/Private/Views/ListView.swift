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

    private let viewModel: ListViewModel
    private let layout: ListViewLayout
    private let onPrimaryVideoSelection: (StreamSource) -> Void
    private let onSecondaryVideoSelection: (StreamSource) -> Void
    @State private var deviceOrientation: UIDeviceOrientation = UIDeviceOrientation.portrait

    init(
        viewModel: ListViewModel,
        layout: ListViewLayout = .topVertical(),
        onPrimaryVideoSelection: @escaping (StreamSource) -> Void,
        onSecondaryVideoSelection: @escaping (StreamSource) -> Void
    ) {
        self.viewModel = viewModel
        self.layout = layout
        self.onPrimaryVideoSelection = onPrimaryVideoSelection
        self.onSecondaryVideoSelection = onSecondaryVideoSelection
    }

    var body: some View {
        GeometryReader { proxy in
            VStack {
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
        }
        .overlay(alignment: .topLeading) {
            LiveIndicatorView()
                .padding(5)
        }
        .onRotate { newOrientation in
            if !newOrientation.isFlat && newOrientation.isValidInterfaceOrientation {
                deviceOrientation = newOrientation
            }
        }
    }

    private func topVerticalLayout(_ screenSize: CGSize, _ columnsCount: Int) -> some View {
        let columns = [GridItem](repeating: GridItem(.flexible(), spacing: Layout.spacing1x), count: columnsCount)
        return ScrollView {
            LazyVGrid(columns: columns, alignment: .leading, pinnedViews: [.sectionHeaders]) {
                Section(
                    header: HStack {
                        let maxAllowedMainVideoSize = CGSize(
                            width: screenSize.width,
                            height: screenSize.height * Defaults.maximumNumberOfTilesRatio
                        )
                        mainView(maxAllowedMainVideoSize)
                    }
                        .clipped()
                ) {
                    gridVertical(screenSize, thumbnailRatioForColumnCount(columnCount: columnsCount))
                }
            }
            Spacer()
        }
    }

    private func topHorizontalLayout(_ screenSize: CGSize, _ rowsCount: Int) -> some View {
        VStack {
            let maxAllowedMainVideoSize = CGSize(
                width: screenSize.width,
                height: screenSize.height * Defaults.maximumNumberOfTilesRatio
            )
            mainView(maxAllowedMainVideoSize)
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
                        let maxAllowedMainVideoSize = CGSize(
                            width: screenSize.width,
                            height: screenSize.height * Defaults.maximumNumberOfTilesRatio
                        )
                        mainView(maxAllowedMainVideoSize)
                    }
                        .clipped()
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
            mainView(maxAllowedMainVideoSize)
            Spacer()
        }
    }

    private func leadingVerticalLayout(_ screenSize: CGSize) -> some View {
        let columns = [GridItem](repeating: GridItem(.flexible(), spacing: Layout.spacing1x), count: 1)
        return HStack(alignment: .top) {
            let maxAllowedMainVideoSize = CGSize(
                width: screenSize.width * Defaults.sideMainViewSizeRatio,
                height: screenSize.height
            )

            mainView(maxAllowedMainVideoSize)
            ScrollView {
                LazyVGrid(columns: columns, alignment: .leading) {
                    gridVertical(screenSize, Defaults.sideListThumbnailSizeRatio)
                }
            }.frame(width: CGFloat(screenSize.width) * Defaults.sideListThumbnailSizeRatio)
        }
    }

    private func trailingVerticalLayout(_ screenSize: CGSize) -> some View {
        let columns = [GridItem](repeating: GridItem(.flexible(), spacing: Layout.spacing1x), count: 1)
        return HStack(alignment: .top) {
            ScrollView {
                LazyVGrid(columns: columns, alignment: .trailing) {
                    gridVertical(screenSize, Defaults.sideListThumbnailSizeRatio)
                }
            }
            .frame(width: CGFloat(screenSize.width) * Defaults.sideListThumbnailSizeRatio)
            let maxAllowedMainVideoSize = CGSize(
                width: screenSize.width * Defaults.sideMainViewSizeRatio,
                height: screenSize.height
            )
            mainView(maxAllowedMainVideoSize)
        }
    }

    private func mainView(_ maxAllowedMainVideoSize: CGSize) -> some View {
        let viewModel = viewModel.primaryVideoViewModel
        return VideoRendererView(
            viewModel: viewModel,
            maxWidth: maxAllowedMainVideoSize.width,
            maxHeight: maxAllowedMainVideoSize.height,
            contentMode: .aspectFit
        ) { source in
            onPrimaryVideoSelection(source)
        }
    }

    private func gridVertical(_ screenSize: CGSize, _ thumbnailSizeRatio: CGFloat) -> ForEach<[VideoRendererViewModel], UUID, VideoRendererView> {
        return ForEach(viewModel.secondaryVideoViewModels, id: \.streamSource.id) { viewModel in
            let maxAllowedSubVideoWidth = screenSize.width * thumbnailSizeRatio
            let maxAllowedSubVideoHeight = screenSize.height * thumbnailSizeRatio

            VideoRendererView(
                viewModel: viewModel,
                maxWidth: maxAllowedSubVideoWidth,
                maxHeight: maxAllowedSubVideoHeight,
                contentMode: .aspectFit
            ) { source in
                onSecondaryVideoSelection(source)
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

    private func gridHorizontal(availableHeight: CGFloat, rowsCount: Int) -> LazyHGrid<ForEach<[VideoRendererViewModel], UUID, VideoRendererView>> {
        let rows = [GridItem](repeating: GridItem(.fixed(CGFloat(availableHeight)), spacing: Layout.spacing1x), count: rowsCount)

        return LazyHGrid(rows: rows, alignment: .top, spacing: Layout.spacing1x) {
            ForEach(viewModel.secondaryVideoViewModels, id: \.streamSource.id) { viewModel in
                VideoRendererView(
                    viewModel: viewModel,
                    maxWidth: .infinity,
                    maxHeight: availableHeight,
                    contentMode: .aspectFit
                ) { source in
                    onSecondaryVideoSelection(source)
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

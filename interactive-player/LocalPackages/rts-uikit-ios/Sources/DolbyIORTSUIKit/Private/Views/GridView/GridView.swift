//
//  GridView.swift
//
//

import SwiftUI
import DolbyIORTSCore
import DolbyIOUIKit

struct GridView: View {
    private enum Defaults {
        static let defaultThumbnailSizeRatio: CGFloat = 1 / 3

        static let defaultCellCountVerticalPortrait = 1
        static let defaultCellCountVerticalLandscape = 2
        static let defaultCellCountHorizontalPortrait = 4
        static let defaultCellCountHorizontalLandscape = 2
    }

    /**
     GridViewLayout describes the layout modes for the GridView:
     horizontal - horizontally scrollable grid, where rowsPortrait - number rows in portrait mode; rowsLandscape - number of rows in landscape mode
     vertical - vertically scrollable grid, where columnsPortrait - number columns in portrait mode; columnsLandscape - number of columns in landscape mode
     */
    enum GridViewLayout {
        case horizontal(rowsPortrait: Int = Defaults.defaultCellCountHorizontalPortrait, rowsLandscape: Int = Defaults.defaultCellCountHorizontalLandscape)
        case vertical(columnsPortrait: Int = Defaults.defaultCellCountVerticalPortrait, columnsLandscape: Int = Defaults.defaultCellCountVerticalLandscape)
    }

    private let viewModel: GridViewModel
    private let layout: GridViewLayout
    private let onVideoSelection: (StreamSource) -> Void
    @State private var deviceOrientation: UIDeviceOrientation = UIDeviceOrientation.portrait

    init(
        viewModel: GridViewModel,
        layout: GridViewLayout = .vertical(),
        onVideoSelection: @escaping (StreamSource) -> Void
    ) {
        self.viewModel = viewModel
        self.layout = layout
        self.onVideoSelection = onVideoSelection
    }

    var body: some View {
        GeometryReader { proxy in
            VStack {
                let screenSize = proxy.size
                switch layout {
                case .horizontal(rowsPortrait: let rowsPortrait, rowsLandscape: let rowsLandscape):
                    gridHorizontal(screenSize.height, deviceOrientation.isPortrait ? rowsPortrait : rowsLandscape)
                case .vertical(columnsPortrait: let columnsPortrait, columnsLandscape: let columnsLandscape):
                    gridVertical(screenSize, deviceOrientation.isPortrait ? columnsPortrait : columnsLandscape)
                }
            }
        }
        .onRotate { newOrientation in
            if !newOrientation.isFlat && newOrientation.isValidInterfaceOrientation {
                deviceOrientation = newOrientation
            }
        }
    }

    private func gridVertical(_ screenSize: CGSize, _ columnsCount: Int) -> some View {
        let thumbnailSizeRatio = thumbnailRatioForColumnCount(columnCount: columnsCount)
        let columns = [GridItem](repeating: GridItem(.flexible(), spacing: Layout.spacing1x), count: columnsCount)
        return ScrollView {
            LazyVGrid(columns: columns, alignment: .leading) {
                ForEach(viewModel.allVideoViewModels, id: \.streamSource.id) { videoViewModel in
                    let maxAllowedSubVideoWidth = screenSize.width * thumbnailSizeRatio
                    let maxAllowedSubVideoHeight = screenSize.height * thumbnailSizeRatio

                    VideoRendererView(
                        viewModel: videoViewModel,
                        viewRenderer: viewModel.viewRendererProvider.renderer(for: videoViewModel.streamSource, isPortait: deviceOrientation.isPortrait),
                        maxWidth: maxAllowedSubVideoWidth,
                        maxHeight: maxAllowedSubVideoHeight,
                        contentMode: .aspectFit,
                        identifier: "GridViewVideoTile.\(videoViewModel.streamSource.sourceId.displayLabel)"
                    ) { source in
                        onVideoSelection(source)
                    }
                    .id(videoViewModel.streamSource.id)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
        }
    }

    private func gridHorizontal(_ availableHeight: CGFloat, _ rowsCount: Int) -> some View {
        let rows = [GridItem](repeating: GridItem(.fixed((availableHeight - (Layout.spacing1x * CGFloat(rowsCount))) / CGFloat(rowsCount)), spacing: Layout.spacing1x), count: rowsCount)

        return ScrollView(.horizontal) {
            LazyHGrid(rows: rows, alignment: .top, spacing: Layout.spacing1x) {
                ForEach(viewModel.allVideoViewModels, id: \.streamSource.id) { videoViewModel in
                    VideoRendererView(
                        viewModel: videoViewModel,
                        viewRenderer: viewModel.viewRendererProvider.renderer(for: videoViewModel.streamSource, isPortait: deviceOrientation.isPortrait),
                        maxWidth: .infinity,
                        maxHeight: availableHeight / CGFloat(rowsCount),
                        contentMode: .aspectFit,
                        identifier: "GridViewVideoTile.\(videoViewModel.streamSource.sourceId.displayLabel)"
                    ) { source in
                        onVideoSelection(source)
                    }
                    .id(videoViewModel.streamSource.id)
                }
            }.frame(height: availableHeight)
        }
    }

    func thumbnailRatioForColumnCount(columnCount: Int) -> CGFloat {
        return 1 / CGFloat(columnCount)
    }
}

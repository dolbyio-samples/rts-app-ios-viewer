//
//  ListView.swift
//

import SwiftUI
import DolbyIORTSCore
import DolbyIOUIKit

struct ListView: View {
    private enum Defaults {
        static let maximumNumberOfTilesRatio: CGFloat = 1 / 3
    }

    private let viewModel: ListViewModel
    private let onPrimaryVideoSelection: (StreamSource) -> Void
    private let onSecondaryVideoSelection: (StreamSource) -> Void

    private let columns = [GridItem(.flexible(), spacing: Layout.spacing1x), GridItem(.flexible(), spacing: Layout.spacing1x)]

    init(
        viewModel: ListViewModel,
        onPrimaryVideoSelection: @escaping (StreamSource) -> Void,
        onSecondaryVideoSelection: @escaping (StreamSource) -> Void
    ) {
        self.viewModel = viewModel
        self.onPrimaryVideoSelection = onPrimaryVideoSelection
        self.onSecondaryVideoSelection = onSecondaryVideoSelection
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
            ScrollView {
                let maxAllowedMainVideoWidth = proxy.size.width
                let maxAllowedMainVideoHeight = proxy.size.height * Defaults.maximumNumberOfTilesRatio

                LazyVGrid(columns: columns, pinnedViews: [.sectionHeaders]) {
                    Section(
                        header: HStack {
                            let primaryVideoViewModel = viewModel.primaryVideoViewModel
                            VideoRendererView(
                                viewModel: viewModel.primaryVideoViewModel,
                                maxWidth: maxAllowedMainVideoWidth,
                                maxHeight: maxAllowedMainVideoHeight,
                                contentMode: .scaleToFill
                            ) { source in
                                onPrimaryVideoSelection(source)
                            }
                        }
                            .clipped()
                    ) {
                        ForEach(viewModel.secondaryVideoViewModels, id: \.streamSource.id) { viewModel in
                            let maxAllowedSubVideoWidth = proxy.size.width / 2
                            let maxAllowedSubVideoHeight = proxy.size.height * Defaults.maximumNumberOfTilesRatio / 2

                            VideoRendererView(
                                viewModel: viewModel,
                                maxWidth: maxAllowedSubVideoWidth,
                                maxHeight: maxAllowedSubVideoHeight,
                                contentMode: .scaleToFill
                            ) { source in
                                onSecondaryVideoSelection(source)
                            }
                        }
                    }
                }
            }
        }
    }
}

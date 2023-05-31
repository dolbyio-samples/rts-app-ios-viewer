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

    @ObservedObject private var viewModel: StreamViewModel
    private var onMainSourceSelection: () -> Void

    private let columns = [GridItem(.flexible(), spacing: Layout.spacing1x), GridItem(.flexible(), spacing: Layout.spacing1x)]

    init(viewModel: StreamViewModel, onMainSourceSelection: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onMainSourceSelection = onMainSourceSelection
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
                ScrollView {
                    let maxAllowedMainVideoWidth = proxy.size.width
                    let maxAllowedMainVideoHeight = proxy.size.height * Defaults.maximumNumberOfTilesRatio

                    LazyVGrid(columns: columns, pinnedViews: [.sectionHeaders]) {
                        Section(
                            header: HStack {
                                if let source = viewModel.selectedVideoSource {
                                    VideoRendererView(
                                        source: source,
                                        maxWidth: maxAllowedMainVideoWidth,
                                        maxHeight: maxAllowedMainVideoHeight,
                                        contentMode: .scaleToFill
                                    )
                                    .overlay(
                                        viewModel.selectedAudioSource == source ? audioPlaybackIndicatorView : nil
                                    )
                                    .onTapGesture {
                                        onMainSourceSelection()
                                    }
                                }
                            }
                                .clipped()
                        ) {
                            ForEach(viewModel.otherSources, id: \.id) { subVideosource in
                                let maxAllowedSubVideoWidth = proxy.size.width / 2
                                let maxAllowedSubVideoHeight = proxy.size.height * Defaults.maximumNumberOfTilesRatio / 2

                                VideoRendererView(
                                    source: subVideosource,
                                    maxWidth: maxAllowedSubVideoWidth,
                                    maxHeight: maxAllowedSubVideoHeight,
                                    contentMode: .scaleToFill
                                )
                                .overlay(
                                    viewModel.selectedAudioSource == subVideosource ? audioPlaybackIndicatorView : nil
                                )
                                .onTapGesture {
                                    viewModel.selectVideoSource(subVideosource)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

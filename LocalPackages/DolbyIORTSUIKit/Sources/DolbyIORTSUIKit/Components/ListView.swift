//
//  ListView.swift
//

import Foundation
import SwiftUI
import DolbyIORTSCore

struct ListView: View {
    private var viewModel: StreamViewModel
    private var highlighted: Int
    private var onHighlightedChange: (Int) -> Void
    private var onHighlightedClick: () -> Void

    let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    init(viewModel: StreamViewModel, highlighted: Int, onHighlightedChange: @escaping (Int) -> Void, onHighlightedClick: @escaping () -> Void) {
        self.viewModel = viewModel
        self.highlighted = highlighted
        self.onHighlightedChange = onHighlightedChange
        self.onHighlightedClick = onHighlightedClick
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                let w = Float(geometry.size.width)
                let h = Float(geometry.size.height) / 3
                if let videoSource = videoSourceFrom(index: highlighted),
                    let viewProvider = viewModel.streamCoordinator.mainSourceViewProvider(for: videoSource) {
                    let videoSize = viewModel.calculateVideoSize(videoSourceDimensions: StreamSource.Dimensions(width: videoSource.width, height: videoSource.height), frameWidth: w, frameHeight: h)
                    VideoRendererView(viewProvider: viewProvider).frame(width: CGFloat(videoSize.width), height: CGFloat(videoSize.height))
                        .onAppear {
                            StreamCoordinator.shared.playVideo(for: videoSource, quality: .auto)
                        }
                        .onDisappear {
                            StreamCoordinator.shared.stopVideo(for: videoSource)
                        }
                        .onTapGesture {
                            onHighlightedClick()
                        }
                    ScrollView {
                        LazyVGrid(columns: columns) {
                            ForEach(
                                0..<(viewModel.sources.count - 1),
                                id: \.self) { i in
                                    let index: Int = highlighted <= i ? i + 1 : i
                                    if let gridVideoSource = videoSourceFrom(index: index),
                                        let viewProvider = viewModel.streamCoordinator.subSourceViewProvider(for: gridVideoSource) {
                                        VideoRendererView(viewProvider: viewProvider)
                                            .frame(width: CGFloat(videoSize.width / 2), height: CGFloat(videoSize.height / 2))
                                            .onTapGesture {
                                                onHighlightedChange(index)
                                            }
                                            .onAppear {
                                                StreamCoordinator.shared.playVideo(for: gridVideoSource, quality: .auto)
                                            }
                                            .onDisappear {
                                                StreamCoordinator.shared.stopVideo(for: videoSource)
                                            }
                                    }
                                }
                        }
                    }
                }
            }
        }
    }

    private func videoSourceFrom(index: Int) -> StreamSource? {
        return viewModel.sources.count > index ? viewModel.sources[index] : nil
    }
}

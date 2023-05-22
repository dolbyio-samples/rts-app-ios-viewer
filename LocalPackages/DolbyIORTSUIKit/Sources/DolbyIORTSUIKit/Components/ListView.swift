//
//  ListView.swift
//

import Foundation
import SwiftUI
import DolbyIORTSCore

struct ListView: View {
    private var viewModel: StreamViewModel
    private var highlighted: Int
    private var onHighlighted: (Int) -> Void

    let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    init(viewModel: StreamViewModel, highlighted: Int, onHighlighted: @escaping (Int) -> Void) {
        self.viewModel = viewModel
        self.highlighted = highlighted
        self.onHighlighted = onHighlighted
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                let w = Float(geometry.size.width)
                let h = Float(geometry.size.height) / 3
                if let videoSource = videoSourceFrom(index: highlighted) {
                    let videoSize = viewModel.calculateVideoSize(videoSourceDimensions: StreamSource.Dimensions(width: videoSource.width, height: videoSource.height), frameWidth: w, frameHeight: h)
                    if let view = viewModel.streamCoordinator.mainSourceViewProvider(for: videoSource)?.playbackView {
                        VideoRendererView(uiView: view).frame(width: CGFloat(videoSize.width), height: CGFloat(videoSize.height))
                            .onAppear {
                                StreamCoordinator.shared.playVideo(for: videoSource, quality: .auto)
                            }
                            .onDisappear {
                                StreamCoordinator.shared.stopVideo(for: videoSource)
                            }
                    }
                    ScrollView {
                        LazyVGrid(columns: columns) {
                            ForEach(
                                0..<viewModel.sources.count,
                                id: \.self) { index in
                                    if let gridVideoSource = videoSourceFrom(index: index) {
                                        if let view = viewModel.streamCoordinator.subSourceViewProvider(for: gridVideoSource)?.playbackView {
                                            VideoRendererView(uiView: view)
                                                .frame(width: CGFloat(videoSize.width / 2), height: CGFloat(videoSize.height / 2), alignment: Alignment.trailing)
                                                .onTapGesture {
                                                    onHighlighted(index)
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
    }

    private func videoSourceFrom(index: Int) -> StreamSource? {
        return viewModel.sources.count > index ? viewModel.sources[index] : nil
    }
}
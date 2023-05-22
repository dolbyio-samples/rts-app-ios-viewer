//
//  ListView.swift
//

import Foundation
import SwiftUI
import DolbyIORTSCore

struct ListView: View {
    private var viewModel: StreamViewModel
    private var selectedSourceIndex: Int
    private var onSelectedSourceIndexChange: (Int) -> Void
    private var onSelectedSourceClick: () -> Void

    let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    init(viewModel: StreamViewModel, selectedSourceIndex: Int, onSelectedSourceIndexChange: @escaping (Int) -> Void, onSelectedSourceClick: @escaping () -> Void) {
        self.viewModel = viewModel
        self.selectedSourceIndex = selectedSourceIndex
        self.onSelectedSourceIndexChange = onSelectedSourceIndexChange
        self.onSelectedSourceClick = onSelectedSourceClick
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                let w = Float(geometry.size.width)
                let h = Float(geometry.size.height) / 3
                if let videoSource = videoSourceFrom(index: selectedSourceIndex),
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
                            onSelectedSourceClick()
                        }
                    ScrollView {
                        LazyVGrid(columns: columns) {
                            ForEach(
                                0..<(viewModel.sources.count - 1),
                                id: \.self) { i in
                                    let index: Int = selectedSourceIndex <= i ? i + 1 : i
                                    if let gridVideoSource = videoSourceFrom(index: index),
                                        let viewProvider = viewModel.streamCoordinator.subSourceViewProvider(for: gridVideoSource) {
                                        VideoRendererView(viewProvider: viewProvider)
                                            .frame(width: CGFloat(videoSize.width / 2), height: CGFloat(videoSize.height / 2))
                                            .onTapGesture {
                                                onSelectedSourceIndexChange(index)
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

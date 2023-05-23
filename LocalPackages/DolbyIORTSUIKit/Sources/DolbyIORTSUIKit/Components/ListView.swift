//
//  ListView.swift
//

import SwiftUI
import DolbyIORTSCore

struct ListView: View {
    private var viewModel: StreamViewModel
    private var highlightedIndex: Int
    private var selectedSourceIndex: Int
    private var onSelectedSourceIndexChange: (Int) -> Void
    private var onSelectedSourceClick: () -> Void

    let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    init(viewModel: StreamViewModel, highlightedIndex: Int, selectedSourceIndex: Int, onSelectedSourceIndexChange: @escaping (Int) -> Void, onSelectedSourceClick: @escaping () -> Void) {
        self.viewModel = viewModel
        self.highlightedIndex = highlightedIndex
        self.selectedSourceIndex = selectedSourceIndex
        self.onSelectedSourceIndexChange = onSelectedSourceIndexChange
        self.onSelectedSourceClick = onSelectedSourceClick
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                let w = Float(geometry.size.width)
                let h = Float(geometry.size.height) / 3
                if let streamSource = videoSourceFrom(index: selectedSourceIndex),
                   let viewProvider = viewModel.streamCoordinator.mainSourceViewProvider(for: streamSource) {
                    let videoSize = viewModel.calculateVideoSize(videoSourceDimensions: CGSize(width: streamSource.width, height: streamSource.height), frameWidth: w, frameHeight: h)
                    VideoRendererView(viewProvider: viewProvider)
                        .overlay(highlightedIndex == selectedSourceIndex ? Rectangle()
                            .stroke(
                                Color(uiColor: UIColor.red),
                                lineWidth: 3
                            ) : nil)
                        .frame(width: CGFloat(videoSize.width), height: CGFloat(videoSize.height))
                        .onAppear {
                            StreamCoordinator.shared.playAudio(for: streamSource)
                            StreamCoordinator.shared.playVideo(for: streamSource, quality: .auto)
                        }
                        .onDisappear {
                            StreamCoordinator.shared.stopAudio(for: streamSource)
                            StreamCoordinator.shared.stopVideo(for: streamSource)
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
                                            .overlay(highlightedIndex == index ? Rectangle()
                                                .stroke(
                                                    Color(uiColor: UIColor.red),
                                                    lineWidth: 3
                                                ) : nil)
                                            .frame(width: CGFloat(videoSize.width / 2), height: CGFloat(videoSize.height / 2))
                                            .onTapGesture {
                                                onSelectedSourceIndexChange(index)
                                            }
                                            .onAppear {
                                                StreamCoordinator.shared.playVideo(for: gridVideoSource, quality: .auto)
                                            }
                                            .onDisappear {
                                                StreamCoordinator.shared.stopVideo(for: gridVideoSource)
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

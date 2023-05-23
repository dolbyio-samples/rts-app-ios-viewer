//
//  ListView.swift
//

import SwiftUI
import DolbyIORTSCore
import DolbyIOUIKit

struct ListView: View {
    private var viewModel: StreamViewModel
    private var selectedAudioIndex: Int
    private var selectedVideoIndex: Int
    private var onSelectVideoSource: (Int) -> Void
    private var onChangeOfViewMode: () -> Void

    let columns = [GridItem(.flexible(), spacing: Layout.spacing1x), GridItem(.flexible(), spacing: Layout.spacing1x)]

    init(viewModel: StreamViewModel, selectedAudioIndex: Int, selectedVideoIndex: Int, onSelectVideoSource: @escaping (Int) -> Void, onChangeOfViewMode: @escaping () -> Void) {
        self.viewModel = viewModel
        self.selectedAudioIndex = selectedAudioIndex
        self.selectedVideoIndex = selectedVideoIndex
        self.onSelectVideoSource = onSelectVideoSource
        self.onChangeOfViewMode = onChangeOfViewMode
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                let w = Float(geometry.size.width)
                let h = Float(geometry.size.height) / 3
                if let streamSource = videoSourceFrom(index: selectedVideoIndex),
                   let viewProvider = viewModel.streamCoordinator.mainSourceViewProvider(for: streamSource) {
                    let videoSize = viewModel.calculateVideoSize(videoSourceDimensions: CGSize(width: streamSource.width, height: streamSource.height), frameWidth: w, frameHeight: h)
                    ScrollView {
                        LazyVGrid(columns: columns, pinnedViews: [.sectionHeaders]) {
                            Section(header: VideoRendererView(viewProvider: viewProvider)
                                .overlay(selectedAudioIndex == selectedVideoIndex ? Rectangle()
                                    .stroke(
                                        Color(uiColor: UIColor.Primary.neonPurple400),
                                        lineWidth: Layout.border2x
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
                                    onChangeOfViewMode()
                                }
                            ) {
                                ForEach(
                                    0..<(viewModel.sources.count - 1),
                                    id: \.self) { i in
                                        let index: Int = selectedVideoIndex <= i ? i + 1 : i
                                        if let gridVideoSource = videoSourceFrom(index: index),
                                           let viewProvider = viewModel.streamCoordinator.subSourceViewProvider(for: gridVideoSource) {
                                            VideoRendererView(viewProvider: viewProvider)
                                                .overlay(selectedAudioIndex == index ? Rectangle()
                                                    .stroke(
                                                        Color(uiColor: UIColor.Primary.neonPurple300),
                                                        lineWidth: Layout.border2x
                                                    ) : nil)
                                                .frame(width: CGFloat(videoSize.width / 2), height: CGFloat(videoSize.height / 2))
                                                .onTapGesture {
                                                    onSelectVideoSource(index)
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
    }

    private func videoSourceFrom(index: Int) -> StreamSource? {
        return viewModel.sources.count > index ? viewModel.sources[index] : nil
    }
}

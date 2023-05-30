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

    private var layout: ListViewLayout

    private let columns = [GridItem(.flexible(), spacing: Layout.spacing1x), GridItem(.flexible(), spacing: Layout.spacing1x)]

    init(viewModel: StreamViewModel, onMainSourceSelection: @escaping () -> Void, layout: ListViewLayout = .topHorizontal()) {
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

    var body: some View {
        GeometryReader { proxy in
            if viewModel.isStreamActive {
                let screenSize = CGSize(width: proxy.size.width, height: proxy.size.height)
                ScrollView {
                    switch layout {
                    case .topVertical(columns: let columns):
                        topVerticalLayout(screenSize, columns)
                    case .topHorizontal(rows: let rows):
                        topHorizontalLayout(screenSize, rows)
                    case .bottomVertical(columns: let columns):
                        bottomVerticalLayout(screenSize, columns)
                    case .bottomHorizontal(rows: let rows):
                        bottomHorizontalLayout(screenSize, rows)
                    case .leftVertical:
                        leftVerticalLayout(screenSize)
                    case .rightVertical:
                        rightVerticalLayout(screenSize)
                    }
                }
            }
        }
    }

    fileprivate func topVerticalLayout(_ screenSize: CGSize, _ rowsCount: Int) -> some View {
        LazyVGrid(columns: columns, pinnedViews: [.sectionHeaders]) {
            Section(
                header: HStack {
                    if let source = viewModel.selectedVideoSource, let mainViewProvider = viewModel.mainViewProvider(for: source) {
                        mainView(screenSize, mainViewProvider, source)
                    }
                }
                    .clipped()
            ) {
                grid(screenSize: screenSize)
            }
        }
    }

    fileprivate func topHorizontalLayout(_ screenSize: CGSize, _ rowsCount: Int) -> some View {
        LazyHGrid(rows: columns, pinnedViews: [.sectionHeaders]) {
            Section(
                header: HStack {
                    if let source = viewModel.selectedVideoSource, let mainViewProvider = viewModel.mainViewProvider(for: source) {
                        mainView(screenSize, mainViewProvider, source)
                    }
                }
                    .clipped()
            ) {
                grid(screenSize: screenSize)
            }
        }
    }

    fileprivate func bottomVerticalLayout(_ screenSize: CGSize, _ rowsCount: Int) -> some View {
        LazyVGrid(columns: columns, pinnedViews: [.sectionFooters]) {
            Section(
                footer: HStack {
                    if let source = viewModel.selectedVideoSource, let mainViewProvider = viewModel.mainViewProvider(for: source) {
                        mainView(screenSize, mainViewProvider, source)
                    }
                }
                    .clipped()
            ) {
                grid(screenSize: screenSize)
            }
        }
    }

    fileprivate func bottomHorizontalLayout(_ screenSize: CGSize, _ rowsCount: Int) -> some View {
        LazyHGrid(rows: columns, pinnedViews: [.sectionFooters]) {
            Section(
                footer: HStack {
                    if let source = viewModel.selectedVideoSource, let mainViewProvider = viewModel.mainViewProvider(for: source) {
                        mainView(screenSize, mainViewProvider, source)
                    }
                }
                    .clipped()
            ) {
                grid(screenSize: screenSize)
            }
        }
    }

    fileprivate func leftVerticalLayout(_ screenSize: CGSize) -> some View {
        let columns = [GridItem](repeating: GridItem(.flexible(), spacing: Layout.spacing1x), count: 1)
        return HStack {
            if let source = viewModel.selectedVideoSource, let mainViewProvider = viewModel.mainViewProvider(for: source) {
                //                let videoSize = viewModel.calculateVideoSize(
                //                    videoSourceDimensions: CGSize(width: streamSource.width, height: streamSource.height),
                //                    frameWidth: w,
                //                    frameHeight: h)
                HStack {
                    mainView(screenSize, mainViewProvider, source)
                    ScrollView {
                        LazyVGrid(columns: columns) {
                            grid(screenSize: screenSize)
                        }
                    }.frame(width: CGFloat(screenSize.width / 4))
                }
            }
        }
    }

    fileprivate func rightVerticalLayout(_ screenSize: CGSize) -> some View {
        let columns = [GridItem](repeating: GridItem(.flexible(), spacing: Layout.spacing1x), count: 1)
        return HStack {
            if let source = viewModel.selectedVideoSource, let mainViewProvider = viewModel.mainViewProvider(for: source) {
                HStack {
                    ScrollView {
                        LazyVGrid(columns: columns) {
                            grid(screenSize: screenSize)
                        }
                    }.frame(width: CGFloat(screenSize.width / 4))
                    mainView(screenSize, mainViewProvider, source)
                }
            }
        }
    }

    private func maxAllowedMainVideoWidth(screenSize: CGSize) -> CGFloat {
        return screenSize.width
    }

    private func maxAllowedMainVideoHeight(screenSize: CGSize) -> CGFloat {
        return screenSize.height * Defaults.maximumNumberOfTilesRatio
    }

    fileprivate func mainView(_ screenSize: CGSize, _ mainViewProvider: SourceViewProviding, _ source: StreamSource) -> some View {
        let videoSize = mainViewProvider.videoViewDisplaySize(
            availableScreenWidth: maxAllowedMainVideoWidth(screenSize: screenSize),
            availableScreenHeight: maxAllowedMainVideoHeight(screenSize: screenSize)
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
    }

    fileprivate func grid(screenSize: CGSize) -> ForEach<[StreamSource], UUID, HStack<(some View)?>> {
        return ForEach(viewModel.otherSources, id: \.id) { subVideosource in
            let maxAllowedSubVideoWidth = screenSize.width / 2
            let maxAllowedSubVideoHeight = screenSize.height * Defaults.maximumNumberOfTilesRatio / 2

            HStack {
                if let subViewProvider = viewModel.subViewProvider(for: subVideosource) {
                    VideoRendererView(viewProvider: subViewProvider)
                        .frame(width: maxAllowedSubVideoWidth, height: maxAllowedSubVideoHeight)
                        .overlay(
                            viewModel.selectedAudioSource == subVideosource ? audioPlaybackIndicatorView : nil
                        )
                        .onTapGesture {
                            viewModel.selectVideoSource(subVideosource)
                        }
                        .onAppear {
                            viewModel.playVideo(for: subVideosource)
                        }
                }
            }
        }
    }

    enum ListViewLayout {
        case leftVertical, rightVertical, bottomHorizontal(rows: Int = 4), bottomVertical(columns: Int = 2), topHorizontal(rows: Int = 4), topVertical(columns: Int = 2)
    }
}

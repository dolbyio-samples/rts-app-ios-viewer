//
//  ChannelGridView.swift
//

import DolbyIOUIKit
import MillicastSDK
import RTSCore
import SwiftUI

struct ChannelGridView: View {
    private let viewModel: ChannelGridViewModel

    static let numberOfColumns = 2

    init(viewModel: ChannelGridViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        GeometryReader { proxy in
            let screenSize = proxy.size
            let tileWidth = screenSize.width / CGFloat(Self.numberOfColumns)
            let columns = [GridItem](repeating: GridItem(.flexible(), spacing: Layout.spacing1x), count: Self.numberOfColumns)

            VideoView(renderer: viewModel.channels[0].rendererRegistry.acceleratedRenderer(for: viewModel.channels[0].source))
            //                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
            //                        .id(channel.source.id)
//            LazyVGrid(columns: columns, alignment: .leading) {
//                ForEach(viewModel.channels) { channel in
//                    Text("Grid View Channel \(channel.source.id)")
//                    VideoView(renderer: channel.rendererRegistry.acceleratedRenderer(for: channel.source))
//                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
//                        .id(channel.source.id)
//                }
//            }
//            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
        }
    }
}

#Preview {
    ChannelGridView(viewModel: ChannelGridViewModel(channels: []))
}

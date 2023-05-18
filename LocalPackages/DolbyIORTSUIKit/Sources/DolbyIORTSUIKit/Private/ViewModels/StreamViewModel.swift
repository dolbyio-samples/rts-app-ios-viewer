//
//  StreamViewModel.swift
//

import Combine
import DolbyIORTSCore
import Foundation

final class StreamViewModel: ObservableObject {

    let streamCoordinator: StreamCoordinator

    private var subscriptions: [AnyCancellable] = []
    @Published private(set) var sources: [StreamSource] = []

    init(streamCoordinator: StreamCoordinator = .shared) {
        self.streamCoordinator = streamCoordinator

        setupStateObservers()
    }

    private func setupStateObservers() {
        streamCoordinator.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                switch state {
                case let .subscribed(sources: sources, numberOfStreamViewers: _):
                    self.sources = sources
                default:
                    break
                }
            }
            .store(in: &subscriptions)
    }

    func calculateVideoSize(videoSourceDimensions: StreamSource.Dimensions, frameWidth: Float, frameHeight: Float) -> StreamSource.Dimensions {
        let ratio = calculateAspectRatio(
            crop: false,
            frameWidth: frameWidth,
            frameHeight: frameHeight,
            videoWidth: videoSourceDimensions.width,
            videoHeight: videoSourceDimensions.height
        )

        let scaledWidth = videoSourceDimensions.width * ratio
        let scaledHeight = videoSourceDimensions.height * ratio
        return StreamSource.Dimensions(width: scaledWidth, height: scaledHeight)
    }

    private func calculateAspectRatio(crop: Bool, frameWidth: Float, frameHeight: Float, videoWidth: Float, videoHeight: Float) -> Float {
        guard videoWidth > 0, videoHeight > 0 else {
            return 0.0
        }

        var ratio: Float = 0
        var widthHeading: Bool = true
        if frameWidth >= videoWidth && frameHeight >= videoHeight {
            if (frameWidth / videoWidth) < (frameHeight / videoHeight) {
                widthHeading = !crop
            } else {
                widthHeading = crop
            }
        } else if frameWidth >= videoWidth {
            widthHeading = crop
        } else if frameHeight >= videoHeight {
            widthHeading = !crop
        } else {
            if (frameWidth / videoWidth) > (frameHeight / videoHeight) {
                widthHeading = crop
            } else {
                widthHeading = !crop
            }
        }
        if widthHeading {
            ratio = frameWidth / videoWidth
        } else {
            ratio = frameHeight / videoHeight
        }
        return ratio
    }

}

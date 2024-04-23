//
//  SourceViewProviding+VideoViewSize.swift
//

import DolbyIORTSCore
import Foundation

extension StreamSourceViewRenderer {

    func videoViewDisplaySize(
        forAvailableScreenWidth screenWidth: CGFloat,
        availableScreenHeight screenHeight: CGFloat,
        shouldCrop: Bool = false
    ) -> CGSize {
        let ratio = calculateAspectRatio(
            crop: shouldCrop,
            screenWidth: screenWidth,
            screenHeight: screenHeight,
            videoWidth: frameWidth,
            videoHeight: frameHeight
        )

        let scaledWidth = frameWidth * ratio
        let scaledHeight = frameHeight * ratio

        return CGSize(width: scaledWidth, height: scaledHeight)
    }

    private func calculateAspectRatio(
        crop: Bool,
        screenWidth: CGFloat,
        screenHeight: CGFloat,
        videoWidth: CGFloat,
        videoHeight: CGFloat
    ) -> CGFloat {
        guard videoWidth > 0, videoHeight > 0 else {
            return 0.0
        }

        var ratio: CGFloat = 0
        var widthHeading: Bool = true
        if screenWidth >= videoWidth && screenHeight >= videoHeight {
            if (screenWidth / videoWidth) < (screenHeight / videoHeight) {
                widthHeading = !crop
            } else {
                widthHeading = crop
            }
        } else if screenWidth >= videoWidth {
            widthHeading = crop
        } else if screenHeight >= videoHeight {
            widthHeading = !crop
        } else {
            if (screenWidth / videoWidth) > (screenHeight / videoHeight) {
                widthHeading = crop
            } else {
                widthHeading = !crop
            }
        }
        if widthHeading {
            ratio = screenWidth / videoWidth
        } else {
            ratio = screenHeight / videoHeight
        }
        return ratio
    }
}

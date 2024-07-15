//
//  PiPManager.swift
//

import AVFoundation
import AVKit
import Foundation
import MillicastSDK
import RTSCore
import os
import UIKit

final class PiPManager: NSObject {
    static let shared: PiPManager = PiPManager()
    static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: VideoRendererViewModel.self)
    )

    private override init() {}

    private(set) var pipVideoCallViewController: AVPictureInPictureVideoCallViewController?
    private(set) var pipController: AVPictureInPictureController?
    private(set) var sampleBufferDisplayLayer: AVSampleBufferDisplayLayer?
    private(set) var pipView: MCSampleBufferVideoUIView?
    private(set) var onStopPictureInPicture: (() -> Void)?

    var isPiPActive: Bool {
        pipController?.isPictureInPictureActive ?? false
    }

    func set(pipRenderer: MCCMSampleBufferVideoRenderer, targetView: UIView, onStopPictureInPicture: @escaping () -> Void) {
        PiPManager.logger.debug("🌄 Set PIP renderer \(pipRenderer) on target view \(targetView)")

        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            return
        }

        let pipView = MCSampleBufferVideoUIView(frame: .zero, renderer: pipRenderer)
        pipView.translatesAutoresizingMaskIntoConstraints = false
        pipView.layer.bounds = targetView.bounds

        let pipVideoCallViewController = AVPictureInPictureVideoCallViewController()
        pipVideoCallViewController.preferredContentSize = targetView.frame.size
        pipVideoCallViewController.view.addSubview(pipView)

        NSLayoutConstraint.activate([
            pipVideoCallViewController.view.topAnchor.constraint(equalTo: pipView.topAnchor),
            pipVideoCallViewController.view.leadingAnchor.constraint(equalTo: pipView.leadingAnchor),
            pipView.bottomAnchor.constraint(equalTo: pipVideoCallViewController.view.bottomAnchor),
            pipView.trailingAnchor.constraint(equalTo: pipVideoCallViewController.view.trailingAnchor)
        ])

        let pipContentSource = AVPictureInPictureController.ContentSource(
            activeVideoCallSourceView: targetView,
            contentViewController: pipVideoCallViewController
        )

        let pipController = AVPictureInPictureController(contentSource: pipContentSource)
        pipController.canStartPictureInPictureAutomaticallyFromInline = true
        pipController.delegate = self

        self.pipView = pipView
        self.sampleBufferDisplayLayer = pipView.sampleBufferDisplayLayer
        self.pipController = pipController
        self.onStopPictureInPicture = onStopPictureInPicture
        self.pipVideoCallViewController = pipVideoCallViewController
    }

    func stopPiP() {
        pipController?.stopPictureInPicture()
        pipController = nil
        pipView = nil
        pipVideoCallViewController = nil
    }
}

extension PiPManager: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        PiPManager.logger.debug("🌄 Started picture in picture")
    }

    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        PiPManager.logger.debug("🌄 Will start picture in picture")
    }

    func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        PiPManager.logger.debug("🌄 Will stop picture in picture")
        onStopPictureInPicture?()
        pipController = nil
        pipView = nil
        pipVideoCallViewController = nil
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        PiPManager.logger.debug("🌄 Stopped picture in picture")
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        PiPManager.logger.debug("🌄 Failed to start picture in picture \(error.localizedDescription)")
    }
}

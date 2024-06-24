//
//  PiPManager.swift
//

import AVFoundation
import AVKit
import Foundation
import MillicastSDK
import DolbyIORTSCore
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
    private(set) var containerView: UIView?
    private(set) var targetView: UIView?
    private(set) var onStopPictureInPicture: (() -> Void)?

    var isPiPActive: Bool {
        pipController?.isPictureInPictureActive ?? false
    }

    func set(pipView: MCSampleBufferVideoUIView, targetView: UIView, onStopPictureInPicture: @escaping () -> Void) {
        VideoRendererViewModel.logger.debug("♼ Set PIP view \(pipView) on target view \(targetView)")

        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            return
        }

        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.layer.bounds = targetView.bounds

        let pipVideoCallViewController = AVPictureInPictureVideoCallViewController()
        pipVideoCallViewController.preferredContentSize = targetView.frame.size
        pipVideoCallViewController.view.addSubview(containerView)

        NSLayoutConstraint.activate([
            pipVideoCallViewController.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            pipVideoCallViewController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            containerView.bottomAnchor.constraint(equalTo: pipVideoCallViewController.view.bottomAnchor),
            containerView.trailingAnchor.constraint(equalTo: pipVideoCallViewController.view.trailingAnchor)
        ])

        let pipContentSource = AVPictureInPictureController.ContentSource(
            activeVideoCallSourceView: targetView,
            contentViewController: pipVideoCallViewController
        )

        let pipController = AVPictureInPictureController(contentSource: pipContentSource)
        pipController.canStartPictureInPictureAutomaticallyFromInline = true
        pipController.delegate = self

        self.containerView = containerView
        self.sampleBufferDisplayLayer = pipView.sampleBufferDisplayLayer
        self.pipController = pipController
        self.targetView = targetView
        self.onStopPictureInPicture = onStopPictureInPicture
        self.pipVideoCallViewController = pipVideoCallViewController
    }

    func stopPiP() {
        pipController?.stopPictureInPicture()
        pipController = nil
        containerView = nil
        targetView = nil
        pipVideoCallViewController = nil
    }
}

extension PiPManager: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        VideoRendererViewModel.logger.debug("♼ Started picture in picture")
        guard
            let sampleBufferDisplayLayer,
            let pipVideoCallViewController
        else {
            return
        }
        sampleBufferDisplayLayer.frame = pipVideoCallViewController.view.bounds
    }

    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        VideoRendererViewModel.logger.debug("♼ Will start picture in picture")
        guard
            let containerView,
            let sampleBufferDisplayLayer
        else {
            return
        }
        sampleBufferDisplayLayer.videoGravity = .resizeAspect
        containerView.layer.addSublayer(sampleBufferDisplayLayer)
    }

    func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        VideoRendererViewModel.logger.debug("♼ Will stop picture in picture")
        onStopPictureInPicture?()
        pipController = nil
        containerView = nil
        targetView = nil
        pipVideoCallViewController = nil
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        VideoRendererViewModel.logger.debug("♼ Stopped picture in picture")
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        VideoRendererViewModel.logger.debug("♼ Failed to start picture in picture \(error.localizedDescription)")
    }
}

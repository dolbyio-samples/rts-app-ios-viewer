//
//  PiPManager.swift
//

import AVFoundation
import AVKit
import Foundation
import MillicastSDK
import UIKit

final class PiPManager: NSObject {
    static let shared: PiPManager = PiPManager()

    private override init() {}

    private(set) var pipController: AVPictureInPictureController?
    private(set) var pipView: MCSampleBufferVideoUIView?

    var isPiPActive: Bool {
        pipController?.isPictureInPictureActive ?? false
    }

    func set(pipView: MCSampleBufferVideoUIView, with targetView: UIView) {
        pipController?.stopPictureInPicture()

        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            return
        }

        let pipVideoCallViewController = AVPictureInPictureVideoCallViewController()
        pipVideoCallViewController.view.addSubview(pipView)
        pipView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            pipVideoCallViewController.view.topAnchor.constraint(equalTo: pipView.topAnchor),
            pipVideoCallViewController.view.leadingAnchor.constraint(equalTo: pipView.leadingAnchor),
            pipView.bottomAnchor.constraint(equalTo: pipVideoCallViewController.view.bottomAnchor),
            pipView.trailingAnchor.constraint(equalTo: pipVideoCallViewController.view.trailingAnchor)
        ])
        pipVideoCallViewController.preferredContentSize = targetView.frame.size

        let pipContentSource = AVPictureInPictureController.ContentSource(
            activeVideoCallSourceView: targetView,
            contentViewController: pipVideoCallViewController
        )

        let pipController = AVPictureInPictureController(contentSource: pipContentSource)
        pipController.canStartPictureInPictureAutomaticallyFromInline = true
        pipController.delegate = self

        NotificationCenter.default
            .addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
                self?.stopPiP()
            }

        self.pipView = pipView
        self.pipController = pipController
    }

    func stopPiP() {
        pipController?.stopPictureInPicture()
    }
}

extension PiPManager: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
    }
}

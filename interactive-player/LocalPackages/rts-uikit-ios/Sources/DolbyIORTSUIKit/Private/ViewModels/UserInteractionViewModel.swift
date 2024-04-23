//
//  UserInteractionViewModel.swift
//

import Foundation

final class UserInteractionViewModel: ObservableObject {

    private enum Constants {
        static let interactivityTimeOut: CGFloat = 5
    }

    // MARK: Manage interactivity on views

    private(set) var interactivityTimer = Timer.publish(every: Constants.interactivityTimeOut, on: .main, in: .common).autoconnect()

    func startInteractivityTimer() {
        interactivityTimer = Timer.publish(every: Constants.interactivityTimeOut, on: .main, in: .common).autoconnect()
    }

    func stopInteractivityTimer() {
        interactivityTimer.upstream.connect().cancel()
    }
}

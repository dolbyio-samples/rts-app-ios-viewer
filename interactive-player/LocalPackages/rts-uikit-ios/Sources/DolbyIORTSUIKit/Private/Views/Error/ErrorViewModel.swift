//
//  ErrorViewModel.swift
//

import DolbyIORTSCore
import Foundation

final class ErrorViewModel {

    let titleText: String
    let subtitleText: String?

    init(titleText: String, subtitleText: String?) {
        self.titleText = titleText
        self.subtitleText = subtitleText
    }

    convenience init(error: Error) {
        let titleAndSubtitle = Self.titleAndSubtitleForError(error)
        self.init(titleText: titleAndSubtitle.title, subtitleText: titleAndSubtitle.subtitle)
    }

    private typealias ErrorTitleAndSubtitle = (title: String, subtitle: String?)
    private static func titleAndSubtitleForError(_ error: Error) -> ErrorTitleAndSubtitle {
        switch error {
        case let streamError as StreamError:
            switch streamError {
            case .connectFailed(reason: _, status: 0):
                // Status code `0` represents a `no network` error code
                return (.noInternetErrorTitle, nil)
            case .connectFailed:
                return (.offlineErrorTitle, .offlineErrorSubtitle)
            default:
                return (.genericErrorTitle, nil)
            }
        default:
            return (.genericErrorTitle, nil)
        }
    }
}

extension ErrorViewModel {
    static var streamOffline: ErrorViewModel {
        ErrorViewModel(
            titleText: .offlineErrorTitle,
            subtitleText: .offlineErrorSubtitle
        )
    }

    static var noInternet: ErrorViewModel {
        ErrorViewModel(
            titleText: .noInternetErrorTitle,
            subtitleText: nil
        )
    }

    static var genericError: ErrorViewModel {
        ErrorViewModel(
            titleText: .genericErrorTitle,
            subtitleText: nil
        )
    }

}

private extension String {
    static var offlineErrorTitle = String(localized: "stream-offline.title.label", bundle: .module)
    static var offlineErrorSubtitle = String(localized: "stream-offline.subtitle.label", bundle: .module)

    static var noInternetErrorTitle = String(localized: "network.disconnected.title.label", bundle: .module)

    static var genericErrorTitle = String(localized: "technical-error.title.label", bundle: .module)
}

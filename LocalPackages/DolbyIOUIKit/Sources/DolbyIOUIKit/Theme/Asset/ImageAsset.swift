//
//  ImageAsset.swift
//  

import Foundation

public enum ImageAsset: String, ImageAssetable {

    // MARK: Arrows and Chevrons

    case arrowLeft = "arrow-left"
    case arrowRight = "arrow-right"
    case textLink = "text-link"
    case chevronLeft = "chevron-left"

    // MARK: Actions

    case loader = "loader"
    case close = "close"
    case playOutlined = "playOutlined"
    case delete = "delete"

    // MARK: Status

    case success = "success-filled"
    case checkmark = "checkmark"

    // MARK: Dolby Logo

    case dolby_logo_dd = "dolby-logo-dd"

    // MARK: Buttons

    case settings = "settings"
    case more = "more"
    case info = "info"
    case liveStream = "live-stream"
    case simulcast = "simulcast"
    case fullScreen = "full-screen"
    case exitFullScreen = "exit-full-screen"
}

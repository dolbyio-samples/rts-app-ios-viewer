//
//  FontAsset.swift
// 

import SwiftUI

public enum FontAsset: FontAssetable {
    case avenirNextRegular(size: CGFloat, style: Font.TextStyle)
    case avenirNextMedium(size: CGFloat, style: Font.TextStyle)
    case avenirNextDemiBold(size: CGFloat, style: Font.TextStyle)
    case avenirNextBold(size: CGFloat, style: Font.TextStyle)
}

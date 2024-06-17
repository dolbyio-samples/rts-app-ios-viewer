//
//  Font+Roboto.swift
//  

import Foundation
import SwiftUI

public extension Font {

    // MARK: Roboto Font's

    static func robotoBlack(withStyle style: Font.TextStyle, size: CGFloat) -> Font {
      return .custom("Roboto-Black", size: size, relativeTo: style)
    }

    static func robotoBlackItalic(withStyle style: Font.TextStyle, size: CGFloat) -> Font {
      return .custom("Roboto-BlackItalic", size: size, relativeTo: style)
    }

    static func robotoBold(withStyle style: Font.TextStyle, size: CGFloat) -> Font {
      return .custom("Roboto-Bold", size: size, relativeTo: style)
    }

    static func robotoBoldItalic(withStyle style: Font.TextStyle, size: CGFloat) -> Font {
      return .custom("Roboto-BoldItalic", size: size, relativeTo: style)
    }

    static func robotoItalic(withStyle style: Font.TextStyle, size: CGFloat) -> Font {
      return .custom("Roboto-Italic", size: size, relativeTo: style)
    }

    static func robotoLight(withStyle style: Font.TextStyle, size: CGFloat) -> Font {
      return .custom("Roboto-Light", size: size, relativeTo: style)
    }

    static func robotoLightItalic(withStyle style: Font.TextStyle, size: CGFloat) -> Font {
      return .custom("Roboto-LightItalic", size: size, relativeTo: style)
    }

    static func robotoMedium(withStyle style: Font.TextStyle, size: CGFloat) -> Font {
      return .custom("Roboto-Medium", size: size, relativeTo: style)
    }

    static func robotoMediumItalic(withStyle style: Font.TextStyle, size: CGFloat) -> Font {
      return .custom("Roboto-MediumItalic", size: size, relativeTo: style)
    }

    static func robotoRegular(withStyle style: Font.TextStyle, size: CGFloat) -> Font {
      return .custom("Roboto-Regular", size: size, relativeTo: style)
    }

    static func robotoThin(withStyle style: Font.TextStyle, size: CGFloat) -> Font {
      return .custom("Roboto-Thin", size: size, relativeTo: style)
    }

    static func robotoThinItalic(withStyle style: Font.TextStyle, size: CGFloat) -> Font {
      return .custom("Roboto-ThinItalic", size: size, relativeTo: style)
    }

}

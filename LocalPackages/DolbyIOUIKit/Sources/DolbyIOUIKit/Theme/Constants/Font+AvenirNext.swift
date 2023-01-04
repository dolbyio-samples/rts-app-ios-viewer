//
//  File.swift
//  
//
//  Created by Raveendran, Aravind on 5/1/2023.
//

import Foundation
import SwiftUI

extension Font {
    
    // MARK: Avenir Next Font's

    static func avenirNextRegular(withStyle style: Font.TextStyle, size: CGFloat) -> Font {
      return .custom("AvenirNext-Regular", size: size, relativeTo: style)
    }
    
    static func avenirNextMedium(withStyle style: Font.TextStyle, size: CGFloat) -> Font {
      return .custom("AvenirNext-Medium", size: size, relativeTo: style)
    }
    
    static func avenirNextDemiBold(withStyle style: Font.TextStyle, size: CGFloat) -> Font {
      return .custom("AvenirNext-DemiBold", size: size, relativeTo: style)
    }
    
    static func avenirNextBold(withStyle style: Font.TextStyle, size: CGFloat) -> Font {
      return .custom("AvenirNext-Bold", size: size, relativeTo: style)
    }
}

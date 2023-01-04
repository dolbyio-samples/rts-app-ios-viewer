//
//  File.swift
//  
//
//  Created by Raveendran, Aravind on 8/1/2023.
//

import UIKit

public extension UIColor {
    
    /// The primary color is the Dolby.io “brand” color, and is used across all interactive elements such as buttons, links, inputs, etc. These colors define the overall feel and elicit emotion.
    enum Primary {
        static let neonPurple25 = UIColor(hex: 0xFDFAFF)
        static let neonPurple50 = UIColor(hex: 0xF4E5FF)
        static let neonPurple100 = UIColor(hex: 0xEACCFF)
        static let neonPurple200 = UIColor(hex: 0xD599FF)
        static let neonPurple300 = UIColor(hex: 0xBF66FF)
        static let neonPurple400 = UIColor(hex: 0xAA33FF)
        static let neonPurple500 = UIColor(hex: 0x8829CC)
        static let neonPurple600 = UIColor(hex: 0x6E21A6)
        static let neonPurple700 = UIColor(hex: 0x551980)
        static let neonPurple800 = UIColor(hex: 0x3B1259)
        static let neonPurple900 = UIColor(hex: 0x220A33)
    }
    
    /// Along with primary colors, it's helpful to have a selection of secondary colors to use in components such as alerts and labels. These secondary colors should be used sparingly or as accents, while the primary color(s) should take precendence.
    enum Secondary {
        static let ultraViolet100 = UIColor(hex: 0xB0B2FF)
        static let ultraViolet200 = UIColor(hex: 0xD599FF)
        static let ultraViolet300 = UIColor(hex: 0xBF66FF)
        static let ultraViolet400 = UIColor(hex: 0xAA33FF)
        static let ultraViolet500 = UIColor(hex: 0x8829CC)
        static let ultraViolet600 = UIColor(hex: 0x6E21A6)
        
        static let articBlue100 = UIColor(hex: 0x78DAFF)
        static let articBlue200 = UIColor(hex: 0x48C6F5)
        static let articBlue300 = UIColor(hex: 0x30B4E6)
        static let articBlue400 = UIColor(hex: 0x2AA0CC)
        static let articBlue500 = UIColor(hex: 0x30B4E6)
        static let articBlue600 = UIColor(hex: 0x30B4E6)

        
        static let magenta100 = UIColor(hex: 0xFFABCB)
        static let magenta200 = UIColor(hex: 0xFC80B0)
        static let magenta300 = UIColor(hex: 0xFF5294)
        static let magenta400 = UIColor(hex: 0xFF2E7E)
        static let magenta500 = UIColor(hex: 0xDA0059)
        static let magenta600 = UIColor(hex: 0xAA174F)
        
        static let emeraldGreen100 = UIColor(hex: 0xCFFEEB)
        static let emeraldGreen200 = UIColor(hex: 0xA1FBD6)
        static let emeraldGreen300 = UIColor(hex: 0x5CF2AF)
        static let emeraldGreen400 = UIColor(hex: 0x00EB81)
        static let emeraldGreen500 = UIColor(hex: 0x0BCB74)
        static let emeraldGreen600 = UIColor(hex: 0x06B365)
    }
    
    /// Gray is a neutral color and is the foundation of the Dolby.io color system. Almost everything in UI design — text, form fields, backgrounds, dividers — are usually gray.
    enum Neutral {
        static let neutral25 = UIColor(hex: 0xFCFCFF)
        static let neutral50 = UIColor(hex: 0xF2F2F2)
        static let neutral100 = UIColor(hex: 0xE6E6E7)
        static let neutral200 = UIColor(hex: 0xBBBBBF)
        static let neutral300 = UIColor(hex: 0x959599)
        static let neutral400 = UIColor(hex: 0x7C7C80)
        static let neutral500 = UIColor(hex: 0x6A6A6D)
        static let neutral600 = UIColor(hex: 0x535359)
        static let neutral700 = UIColor(hex: 0x36363B)
        static let neutral800 = UIColor(hex: 0x292930)
        static let neutral900 = UIColor(hex: 0x14141A)
    }
    
    /// A typeface is the design of lettering that can include variations in size, weight, slope, width, and height. Avenir Next is part of the Platinum Collection and comes in 4 typeface sets, regular, Italic, condensed and condensed Italic weights.
    enum Typography {
        enum Light {
            static let primary = UIColor(hex: 0x6A6A6D)
            static let secondary = UIColor(hex: 0x292930)
            static let tertiary = UIColor(hex: 0x2aa0cc)
        }

        enum Dark {
            static let primary = UIColor(hex: 0xB9B9BA)
            static let secondary = UIColor(hex: 0xFFFFFF)
            static let tertiary = UIColor(hex: 0x35C8FF)
        }
    }

    enum Background {
        static let black = UIColor(hex: 0x14141A)
        static let white = UIColor(hex: 0xFFFFFF)
    }
    
    /// A call to action or CTA communicates to a user to take a specified action.
    enum CTA {
        static let `default` = UIColor(hex: 0xAA33FF)
        static let active = UIColor(hex: 0x8829CC)
        static let focused = UIColor(hex: 0xBF66FF)
        static let selected = UIColor(hex: 0x6E21A6)
    }
    
    /// Feedback colors communicate purpose and denote standard value states (such as good, bad, or warning). Each color has the same basic meaning in all contexts.
    enum Feedback {
        
        /// Success colors commuicate a position action, positive trend, or a successful confirmation.
        static let success25 = UIColor(hex: 0xFAFFFB)
        static let success50 = UIColor(hex: 0xEDFAF0)
        static let success100 = UIColor(hex: 0xD0F5D8)
        static let success200 = UIColor(hex: 0xA6EDB6)
        static let success300 = UIColor(hex: 0x7EE595)
        static let success400 = UIColor(hex: 0x57D974)
        static let success500 = UIColor(hex: 0x29CC4D)
        static let success600 = UIColor(hex: 0x179934)
        static let success700 = UIColor(hex: 0x0A661E)
        static let success800 = UIColor(hex: 0x044D14)
        static let success900 = UIColor(hex: 0x00330B)
        
        /// Invalid colors commuicate an action that is potentially desructive or “on–hold.”
        static let invalid25 = UIColor(hex: 0xFFFDFA)
        static let invalid50 = UIColor(hex: 0xFFFBF2)
        static let invalid100 = UIColor(hex: 0xFFF4D9)
        static let invalid200 = UIColor(hex: 0xFFE8B2)
        static let invalid300 = UIColor(hex: 0xFFD980)
        static let invalid400 = UIColor(hex: 0xFCC84C)
        static let invalid500 = UIColor(hex: 0xFCB91A)
        static let invalid600 = UIColor(hex: 0xCC930A)
        static let invalid700 = UIColor(hex: 0x996D03)
        static let invalid800 = UIColor(hex: 0x664800)
        static let invalid900 = UIColor(hex: 0x332400)
        
        /// Error colors are used across error states and in “destructive” actions.
        static let error25 = UIColor(hex: 0xFFFAFA)
        static let error50 = UIColor(hex: 0xFFF2F2)
        static let error100 = UIColor(hex: 0xFCD7D7)
        static let error200 = UIColor(hex: 0xFAAFAF)
        static let error300 = UIColor(hex: 0xF28585)
        static let error400 = UIColor(hex: 0xEB5252)
        static let error500 = UIColor(hex: 0xFF0025)
        static let error600 = UIColor(hex: 0xB21212)
        static let error700 = UIColor(hex: 0x800303)
        static let error800 = UIColor(hex: 0x590000)
        static let error900 = UIColor(hex: 0x330000)
        
        /// Information colors are used to provide users with information about any actions or states  of an application or system.
        static let info25 = UIColor(hex: 0xFAFDFF)
        static let info50 = UIColor(hex: 0xF2F9FF)
        static let info100 = UIColor(hex: 0xD9EDFF)
        static let info200 = UIColor(hex: 0xAFD6FA)
        static let info300 = UIColor(hex: 0x84BCF0)
        static let info400 = UIColor(hex: 0x52A2EB)
        static let info500 = UIColor(hex: 0x2288E5)
        static let info600 = UIColor(hex: 0x1266B2)
        static let info700 = UIColor(hex: 0x064680)
        static let info800 = UIColor(hex: 0x002F59)
        static let info900 = UIColor(hex: 0x001B33)
    }
}

extension UIColor {
    convenience init(hex: Int, opacity: Double = 1.0) {
        let red = Double((hex & 0xff0000) >> 16) / 255.0
        let green = Double((hex & 0xff00) >> 8) / 255.0
        let blue = Double((hex & 0xff) >> 0) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: opacity)
    }
    
    convenience init(light: UIColor, dark: UIColor) {
        self.init { $0.userInterfaceStyle == .dark ? dark : light }
    }
}

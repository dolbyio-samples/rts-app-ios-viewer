//
//  UIColor++.swift
//  

import UIKit

public extension UIColor {

    /// The primary color is the Dolby.io “brand” color, and is used across all interactive elements such as buttons, links, inputs, etc. These colors define the overall feel and elicit emotion.
    enum Primary {
        public static let neonPurple25 = UIColor(hex: 0xFDFAFF)
        public static let neonPurple50 = UIColor(hex: 0xF4E5FF)
        public static let neonPurple100 = UIColor(hex: 0xEACCFF)
        public static let neonPurple200 = UIColor(hex: 0xD599FF)
        public static let neonPurple300 = UIColor(hex: 0xBF66FF)
        public static let neonPurple400 = UIColor(hex: 0xAA33FF)
        public static let neonPurple500 = UIColor(hex: 0x8829CC)
        public static let neonPurple600 = UIColor(hex: 0x6E21A6)
        public static let neonPurple700 = UIColor(hex: 0x551980)
        public static let neonPurple800 = UIColor(hex: 0x3B1259)
        public static let neonPurple900 = UIColor(hex: 0x220A33)
    }

    /// Along with primary colors, it's helpful to have a selection of secondary colors to use in components such as alerts and labels. These secondary colors should be used sparingly or as accents, while the primary color(s) should take precendence.
    enum Secondary {
        public static let ultraViolet100 = UIColor(hex: 0xB0B2FF)
        public static let ultraViolet200 = UIColor(hex: 0xD599FF)
        public static let ultraViolet300 = UIColor(hex: 0xBF66FF)
        public static let ultraViolet400 = UIColor(hex: 0xAA33FF)
        public static let ultraViolet500 = UIColor(hex: 0x8829CC)
        public static let ultraViolet600 = UIColor(hex: 0x6E21A6)

        public static let articBlue100 = UIColor(hex: 0x78DAFF)
        public static let articBlue200 = UIColor(hex: 0x48C6F5)
        public static let articBlue300 = UIColor(hex: 0x30B4E6)
        public static let articBlue400 = UIColor(hex: 0x2AA0CC)
        public static let articBlue500 = UIColor(hex: 0x30B4E6)
        public static let articBlue600 = UIColor(hex: 0x30B4E6)

        public static let magenta100 = UIColor(hex: 0xFFABCB)
        public static let magenta200 = UIColor(hex: 0xFC80B0)
        public static let magenta300 = UIColor(hex: 0xFF5294)
        public static let magenta400 = UIColor(hex: 0xFF2E7E)
        public static let magenta500 = UIColor(hex: 0xDA0059)
        public static let magenta600 = UIColor(hex: 0xAA174F)

        public static let emeraldGreen100 = UIColor(hex: 0xCFFEEB)
        public static let emeraldGreen200 = UIColor(hex: 0xA1FBD6)
        public static let emeraldGreen300 = UIColor(hex: 0x5CF2AF)
        public static let emeraldGreen400 = UIColor(hex: 0x00EB81)
        public static let emeraldGreen500 = UIColor(hex: 0x0BCB74)
        public static let emeraldGreen600 = UIColor(hex: 0x06B365)
    }

    /// Gray is a neutral color and is the foundation of the Dolby.io color system. Almost everything in UI design — text, form fields, backgrounds, dividers — are usually gray.
    enum Neutral {
        public static let neutral25 = UIColor(hex: 0xFCFCFF)
        public static let neutral50 = UIColor(hex: 0xF2F2F2)
        public static let neutral100 = UIColor(hex: 0xE6E6E7)
        public static let neutral200 = UIColor(hex: 0xBBBBBF)
        public static let neutral300 = UIColor(hex: 0x959599)
        public static let neutral400 = UIColor(hex: 0x7C7C80)
        public static let neutral500 = UIColor(hex: 0x6A6A6D)
        public static let neutral600 = UIColor(hex: 0x535359)
        public static let neutral700 = UIColor(hex: 0x36363B)
        public static let neutral800 = UIColor(hex: 0x292930)
        public static let neutral900 = UIColor(hex: 0x14141A)
    }

    /// A typeface is the design of lettering that can include variations in size, weight, slope, width, and height. Avenir Next is part of the Platinum Collection and comes in 4 typeface sets, regular, Italic, condensed and condensed Italic weights.
    enum Typography {
        public enum Light {
            public static let primary = UIColor(hex: 0x6A6A6D)
            public static let secondary = UIColor(hex: 0x292930)
            public static let tertiary = UIColor(hex: 0x2aa0cc)
        }

        public enum Dark {
            public static let primary = UIColor(hex: 0xFFFFFF)
            public static let secondary = UIColor(hex: 0xB9B9BA)
            public static let tertiary = UIColor(hex: 0x525259)
        }
    }

    enum Background {
        public static let black = UIColor(hex: 0x14141A)
        public static let white = UIColor(hex: 0xFFFFFF)
    }

    /// A call to action or CTA communicates to a user to take a specified action.
    enum CTA {
        public static let `default` = UIColor(hex: 0xAA33FF)
        public static let active = UIColor(hex: 0x8829CC)
        public static let focused = UIColor(hex: 0xBF66FF)
        public static let selected = UIColor(hex: 0x6E21A6)
    }

    /// Feedback colors communicate purpose and denote standard value states (such as good, bad, or warning). Each color has the same basic meaning in all contexts.
    enum Feedback {

        /// Success colors commuicate a position action, positive trend, or a successful confirmation.
        public static let success25 = UIColor(hex: 0xFAFFFB)
        public static let success50 = UIColor(hex: 0xEDFAF0)
        public static let success100 = UIColor(hex: 0xD0F5D8)
        public static let success200 = UIColor(hex: 0xA6EDB6)
        public static let success300 = UIColor(hex: 0x7EE595)
        public static let success400 = UIColor(hex: 0x57D974)
        public static let success500 = UIColor(hex: 0x29CC4D)
        public static let success600 = UIColor(hex: 0x179934)
        public static let success700 = UIColor(hex: 0x0A661E)
        public static let success800 = UIColor(hex: 0x044D14)
        public static let success900 = UIColor(hex: 0x00330B)

        /// Invalid colors commuicate an action that is potentially desructive or “on–hold.”
        public static let invalid25 = UIColor(hex: 0xFFFDFA)
        public static let invalid50 = UIColor(hex: 0xFFFBF2)
        public static let invalid100 = UIColor(hex: 0xFFF4D9)
        public static let invalid200 = UIColor(hex: 0xFFE8B2)
        public static let invalid300 = UIColor(hex: 0xFFD980)
        public static let invalid400 = UIColor(hex: 0xFCC84C)
        public static let invalid500 = UIColor(hex: 0xFCB91A)
        public static let invalid600 = UIColor(hex: 0xCC930A)
        public static let invalid700 = UIColor(hex: 0x996D03)
        public static let invalid800 = UIColor(hex: 0x664800)
        public static let invalid900 = UIColor(hex: 0x332400)

        /// Error colors are used across error states and in “destructive” actions.
        public static let error25 = UIColor(hex: 0xFFFAFA)
        public static let error50 = UIColor(hex: 0xFFF2F2)
        public static let error100 = UIColor(hex: 0xFCD7D7)
        public static let error200 = UIColor(hex: 0xFAAFAF)
        public static let error300 = UIColor(hex: 0xF28585)
        public static let error400 = UIColor(hex: 0xEB5252)
        public static let error500 = UIColor(hex: 0xFF0025)
        public static let error600 = UIColor(hex: 0xB21212)
        public static let error700 = UIColor(hex: 0x800303)
        public static let error800 = UIColor(hex: 0x590000)
        public static let error900 = UIColor(hex: 0x330000)

        /// Information colors are used to provide users with information about any actions or states  of an application or system.
        public static let info25 = UIColor(hex: 0xFAFDFF)
        public static let info50 = UIColor(hex: 0xF2F9FF)
        public static let info100 = UIColor(hex: 0xD9EDFF)
        public static let info200 = UIColor(hex: 0xAFD6FA)
        public static let info300 = UIColor(hex: 0x84BCF0)
        public static let info400 = UIColor(hex: 0x52A2EB)
        public static let info500 = UIColor(hex: 0x2288E5)
        public static let info600 = UIColor(hex: 0x1266B2)
        public static let info700 = UIColor(hex: 0x064680)
        public static let info800 = UIColor(hex: 0x002F59)
        public static let info900 = UIColor(hex: 0x001B33)
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

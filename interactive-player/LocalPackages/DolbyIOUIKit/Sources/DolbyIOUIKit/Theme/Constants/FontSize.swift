//
//  FontSize.swift
//  

import Foundation

public enum FontSize {

    // MARK: Font size's

#if os(tvOS)
    public static let title1: CGFloat = 76.0
    public static let title2: CGFloat = 57.0
    public static let title3: CGFloat = 48.0
    public static let headline: CGFloat = 38.0
    public static let subtitle: CGFloat = 38.0
    public static let callout: CGFloat = 31
    public static let body: CGFloat = 29
    public static let caption1: CGFloat = 25.0
    public static let caption2: CGFloat = 23.0
#else
    public static let largeTitle: CGFloat = 32.0
    public static let title1: CGFloat = 28.0
    public static let title2: CGFloat = 22.0
    public static let title3: CGFloat = 20.0
    public static let headline: CGFloat = 17.0
    public static let body: CGFloat = 17.0
    public static let callout: CGFloat = 16.0
    public static let subhead: CGFloat = 15.0
    public static let footnote: CGFloat = 13.0
    public static let caption1: CGFloat = 12.0
    public static let caption2: CGFloat = 11.0
#endif
}

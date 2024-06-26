//
//  Theme.swift
//  
import SwiftUI

public protocol ThemeProviding {
    associatedtype _ColorAsset: ColorAssetable
    associatedtype _FontAsset: FontAssetable
    associatedtype _ImageAsset: ImageAssetable

    subscript(colorAsset: _ColorAsset) -> Color? { get }
    subscript(fontAsset: _FontAsset) -> Font { get }
    subscript(imageAsset: _ImageAsset) -> Image { get }
}

public protocol ColorAssetable {}

public protocol FontAssetable {}

public protocol ImageAssetable {}

open class AbstractTheme<C: ColorAssetable, F: FontAssetable, I: ImageAssetable>: ThemeProviding {
    public typealias _ColorAsset = C
    public typealias _FontAsset = F
    public typealias _ImageAsset = I

    open subscript(colorAsset: _ColorAsset) -> Color? {
        fatalError("Implement subscript in subclass")
    }

    open subscript(fontAsset: _FontAsset) -> Font {
        fatalError("Implement subscript in subclass")
    }

    open subscript(imageAsset: _ImageAsset) -> Image {
        fatalError("Implement subscript in subclass")
    }
}

public typealias Theme = AbstractTheme<ColorAsset, FontAsset, ImageAsset>

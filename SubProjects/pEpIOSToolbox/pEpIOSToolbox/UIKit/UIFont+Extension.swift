//
//  UIFont+Extension.swift
//  pEpIOSToolbox
//
//  Created by Martin Brude on 04/02/2020.
//  Copyright © 2020 pEp Security SA. All rights reserved.
//

import UIKit

/// UIFont extension that provides fonts based on weight and style.
/// As it is based on the system fonts, it allows to take advantage of Dynamic Type.
/// System fonts automatically react to accessibility features like bold text and larger type.
/// To add a new font, include the font file, add it on Info.plist and add the case here.
/// Usage example: let font = UIFont.pepFont(style: .body, weight: .regular)
extension UIFont {

    static private let medium = "SFUIText-Medium"
    static private let regular = "SFUIText-Regular"
    static private let semibold = "SFUIText-Semibold"

    
    
    
    /// Retrieves the font for the provided style and type
    /// - Parameters:
    ///   - style: The style of the font.
    ///   - weight: The weight of the font.
    public static func pepFont(style: TextStyle,
                               weight: UIFont.Weight) -> UIFont {
        guard let font = UIFont(name: getFontName(from: weight),
                                size: preferredFontSize(for: style)) else {
                                    Log.shared.info("Missing custom font. System default font for specified style is used now.")
                                    return UIFont.systemFont(ofSize: preferredFontSize(for: style),
                                                             weight: weight)
        }
        // We don't want to lose textStyle attribute in our custom fonts!
        font.fontDescriptor.addingAttributes([.textStyle : style])
        font.fontDescriptor.addingAttributes([.family : getFontName(from: weight)])
        return font
    }

    /// Return font - custom typeface from given system default font (Dynamic Font Sizes - Accessibility)
    /// - Parameter systemDynamicFont: system font with specified Text Style
    public static func pEpPreferredFontTypeFace(systemDynamicFont: UIFont, weight: UIFont.Weight?) -> UIFont {
        let defaultWeight = weight ?? getFontWeight(from: systemDynamicFont)
        guard let textStyle = systemDynamicFont.fontDescriptor.object(forKey: .textStyle) as? String else {
                Log.shared.error("Missing UIFont.TextStyle")
                return systemDynamicFont
        }
        let customFont = UIFont.pepFont(style: UIFont.TextStyle.init(rawValue:textStyle),
                                        weight: weight ?? defaultWeight)
        // We don't want to lose textStyle attribute in our custom fonts!
        customFont.fontDescriptor.addingAttributes([.textStyle : textStyle])
        customFont.fontDescriptor.addingAttributes([.family : getFontName(from: weight ?? defaultWeight)])
        return customFont
    }
    
    static private func preferredFontSize(for textStyle: TextStyle) -> CGFloat {
        let customFont = UIFont.preferredFont(forTextStyle: textStyle)
        let pointSize = customFont.pointSize
        // We don't want to lose textStyle attribute in our custom fonts!
        customFont.fontDescriptor.addingAttributes([.textStyle : textStyle])
        return pointSize
    }

    static private func getFontWeight(from font: UIFont) -> UIFont.Weight {
        if let fontName: String = font.fontDescriptor.fontAttributes[.visibleName] as? String {
            if fontName.lowercased().contains(medium.lowercased()) {
                return UIFont.Weight.medium
            } else if fontName.lowercased().contains(semibold.lowercased()) {
                return .semibold
            }
        }
        return .regular
    }

    static private func getFontName(from weight: UIFont.Weight) -> String {
        switch weight {
        case .medium:
            return medium
        case .regular:
            return regular
        case .semibold:
            return semibold
        default:
            return regular
        }
    }
}

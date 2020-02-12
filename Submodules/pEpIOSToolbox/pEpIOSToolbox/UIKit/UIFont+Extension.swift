//
//  UIFont+Extension.swift
//  pEpIOSToolbox
//
//  Created by Martin Brude on 04/02/2020.
//  Copyright © 2020 pEp Security SA. All rights reserved.
//

import Foundation
import UIKit

/// UIFont extension that provides fonts based on weight and style.
/// As it is based on the system fonts, it allows to take advantage of Dynamic Type.
/// System fonts automatically react to accessibility features like bold text and larger type.
/// To add a new font, include the font file, add it on Info.plist and add the case here.
/// Usage example: let font = UIFont.pepFont(style: .body, weight: .regular)
extension UIFont {

    private static let medium = "SFUIText-Medium"
    private static let regular = "SFUIText-Regular"
    private static let semibold = "SFUIText-Semibold"

    /// Retrieves the font for the provided style and type
    /// - Parameters:
    ///   - style: The style of the font.
    ///   - weight: The weight of the font.
    public static func pepFont(style : TextStyle, weight : UIFont.Weight) -> UIFont {
        let name: String
        switch weight {
        case .medium:
            name = medium
        case .regular:
            name = regular
        case .semibold:
            name = semibold
        default:
            name = regular
        }
        
        guard let font = UIFont(name: name, size: preferredFontSize(for: style)) else {
            return UIFont.systemFont(ofSize: preferredFontSize(for: style), weight: weight)
        }
        return font
    }
    
    private static func preferredFontSize(for textStyle : TextStyle) -> CGFloat {
        return UIFont.preferredFont(forTextStyle: textStyle).pointSize
    }
}

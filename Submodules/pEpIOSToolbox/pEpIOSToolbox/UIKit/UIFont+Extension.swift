//
//  UIFont+Extension.swift
//  pEpIOSToolbox
//
//  Created by Martin Brude on 04/02/2020.
//  Copyright © 2020 pEp Security SA. All rights reserved.
//

import Foundation
import UIKit

/// UIFont extension
/// It has static vars that use text styles like body or callout.
/// As it is based on the system fonts, it allows to take advantage of Dynamic Type.
/// System fonts automatically react to accessibility features like bold text and larger type.
/// To add a new font, include the font files, add it on Info.plist, and add access methods here.
extension UIFont {

    private static let medium = "SFUIText-Medium"
    private static let regular = "SFUIText-Regular"
    private static let semibold = "SFUIText-Semibold"

    /// Retrieves the font for the provided style and type
    /// - Parameters:
    ///   - style: The style of the font.
    ///   - type: The type of the font.
    public static func pepFont(style : TextStyle, type : UIFont.Weight) -> UIFont {
        let name: String
        switch type {
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
            return UIFont.systemFont(ofSize: preferredFontSize(for: style), weight: type)
        }
        return font
    }
    
    private static func preferredFontSize(for textStyle : TextStyle) -> CGFloat {
        return UIFont.preferredFont(forTextStyle: textStyle).pointSize
    }
}



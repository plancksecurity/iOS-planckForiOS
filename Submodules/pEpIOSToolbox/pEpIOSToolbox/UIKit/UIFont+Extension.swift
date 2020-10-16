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

    /// Returns the system font used in p≡p configured with the text style and the weight,
    /// scaled for accessibility if needed at max 30 point size.
    ///
    /// - Parameters:
    ///   - style: The preferred font style.
    ///   - weight: The preferred font weight.
    /// - Returns: The configured font.
    @available(iOS 11, *)
    public static func pepFont(style: TextStyle, weight: Weight) -> UIFont {
        let metrics = UIFontMetrics(forTextStyle: style)
        let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        let font = UIFont.systemFont(ofSize: desc.pointSize, weight: weight)
        return metrics.scaledFont(for: font, maximumPointSize: 30)
    }
}

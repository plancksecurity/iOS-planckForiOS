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
    private static let name = "SFUIText-Regular"
    
    public static var pepBody: UIFont {
        return UIFont(name: name, size: preferredFontSize(for: .body))!
    }
    
    public static var pepCallout: UIFont {
        return UIFont(name: name, size: preferredFontSize(for: .callout))!
    }
    
    public static var pepFootnote: UIFont {
        return UIFont(name: name, size: preferredFontSize(for: .footnote))!
    }
    
    private static func preferredFontSize(for textStyle : TextStyle) -> CGFloat {
        return UIFont.preferredFont(forTextStyle: textStyle).pointSize
    }
}

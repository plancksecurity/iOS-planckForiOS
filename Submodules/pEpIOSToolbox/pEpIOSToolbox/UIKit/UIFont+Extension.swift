//
//  UIFont+Extension.swift
//  pEpIOSToolbox
//
//  Created by Martin Brude on 04/02/2020.
//  Copyright © 2020 pEp Security SA. All rights reserved.
//

import Foundation
import UIKit

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

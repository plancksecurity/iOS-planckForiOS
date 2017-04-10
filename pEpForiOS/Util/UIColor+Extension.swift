//
//  UIColor+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

extension UIColor {
    open class var pEpGreen: UIColor {
        get {
            return UIColor(hex: "#4CD964")
        }
    }

    open class var pEpRed: UIColor {
        get {
            return UIColor(hex: "#FF3B30")
        }
    }

    open class var pEpYellow: UIColor {
        get {
            return UIColor(hex: "#FFCC00")
        }
    }

    convenience init(hex: String) {
        var hexstr = hex
        if hexstr.hasPrefix("#") {
            hexstr = String(hexstr.characters.dropFirst())
        }

        var rgbValue: UInt32 = 0
        Scanner(string: hexstr).scanHexInt32(&rgbValue)

        let r = CGFloat((rgbValue >> 16) & 0xff) / 255.0
        let g = CGFloat((rgbValue >> 08) & 0xff) / 255.0
        let b = CGFloat((rgbValue >> 00) & 0xff) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

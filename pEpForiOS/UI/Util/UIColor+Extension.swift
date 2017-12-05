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

    open class var pEpDarkGreen: UIColor {
        get {
            return UIColor(hex: "#1AAA50")
        }
    }

    open class var pEpRed: UIColor {
        get {
            return UIColor(hex: "#FF3B30")
        }
    }

    open class var pEpGray: UIColor {
        get {
            return UIColor(hex: "#8e8e93")
        }
    }

    open class var pEpYellow: UIColor {
        get {
            return UIColor(hex: "#FFCC00")
        }
    }

    /**
     Example use: In trustwords table view cells.
     */
    open class var pEpLightBackground: UIColor {
        get {
            return UIColor(redInt: 242, greenInt: 242, blueInt: 242)
        }
    }

    convenience init(redInt: Int, greenInt: Int, blueInt: Int, alpha: CGFloat = 1.0) {
        self.init(red: CGFloat(redInt) / 255.0,
                  green: CGFloat(greenInt) / 255.0,
                  blue: CGFloat(blueInt) / 255.0,
                  alpha: alpha)
    }

    convenience init(hex: String) {
        var hexstr = hex
        if hexstr.hasPrefix("#") {
            hexstr = String(hexstr.dropFirst())
        }

        var rgbValue: UInt32 = 0
        Scanner(string: hexstr).scanHexInt32(&rgbValue)

        let r = CGFloat((rgbValue >> 16) & 0xff) / 255.0
        let g = CGFloat((rgbValue >> 08) & 0xff) / 255.0
        let b = CGFloat((rgbValue >> 00) & 0xff) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }

    convenience init(hex: Int, alpha: CGFloat = 1.0) {
        self.init(
            red:   CGFloat((hex & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((hex & 0x00FF00) >> 8)  / 255.0,
            blue:  CGFloat((hex & 0x0000FF) >> 0)  / 255.0,
            alpha: alpha
        )
    }
}

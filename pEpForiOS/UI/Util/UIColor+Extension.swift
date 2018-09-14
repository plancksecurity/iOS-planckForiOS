//
//  UIColor+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

extension UIColor {
    static let pEpGreenHex = "#03AA4B"
    static let pEpDarkGreenHex = "#1AAA50"
    static let pEpRedHex = "#FF3B30"
    static let pEpGreyHex = "#8e8e93"
    static let pEpYellowHex = "#FFCC00"
    static let pEpLightBackgroundHex = "#F2F2F2"

    open class var pEpGreen: UIColor {
        get {
            return UIColor(hexString: pEpGreenHex)
        }
    }

    open class var pEpDarkGreen: UIColor {
        get {
            return UIColor(hexString: pEpDarkGreenHex)
        }
    }

    open class var pEpRed: UIColor {
        get {
            return UIColor(hexString: pEpRedHex)
        }
    }

    open class var pEpGray: UIColor {
        get {
            return UIColor(hexString: pEpGreyHex)
        }
    }

    open class var pEpYellow: UIColor {
        get {
            return UIColor(hexString: pEpYellowHex)
        }
    }

    /**
     Example use: In trustwords table view cells.
     */
    open class var pEpLightBackground: UIColor {
        get {
            return UIColor(hexString: pEpLightBackgroundHex)
        }
    }

    convenience init(redInt: Int, greenInt: Int, blueInt: Int, alpha: CGFloat = 1.0) {
        self.init(red: CGFloat(redInt) / 255.0,
                  green: CGFloat(greenInt) / 255.0,
                  blue: CGFloat(blueInt) / 255.0,
                  alpha: alpha)
    }

    convenience init(hexString: String, alpha: CGFloat = 1.0) {
        var theHexString = hexString
        if theHexString.hasPrefix("#") {
            theHexString = String(theHexString.dropFirst())
        }

        var rgbValue: UInt32 = 0
        Scanner(string: theHexString).scanHexInt32(&rgbValue)

        let r = CGFloat((rgbValue >> 16) & 0xff) / 255.0
        let g = CGFloat((rgbValue >> 08) & 0xff) / 255.0
        let b = CGFloat((rgbValue >> 00) & 0xff) / 255.0

        self.init(red: r, green: g, blue: b, alpha: alpha)
    }

    convenience init(intValue32: Int, alpha: CGFloat = 1.0) {
        self.init(
            red: CGFloat((intValue32 & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((intValue32 & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat((intValue32 & 0x0000FF) >> 0) / 255.0,
            alpha: alpha
        )
    }
}

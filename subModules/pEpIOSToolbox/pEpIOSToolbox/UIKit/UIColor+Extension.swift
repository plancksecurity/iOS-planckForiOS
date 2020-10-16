//
//  UIColor+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

extension UIColor {
    public static let pEpGreenHex = "#03AA4B"
    public static let pEpDarkGreenHex = "#1AAA50"
    public static let pEpRedHex = "#FF3B30"
    public static let pEpGreyHex = "#8e8e93"
    public static let pEpGreyLinesHex = "#9F9F9F"
    public static let pEpGreyButtonLinesHex = "#CDCED2"
    public static let pEpGreyTextHex = "#8A8A8F"
    public static let pEpGreyBackgroundHex = "#EDEEED"
    public static let pEpYellowHex = "#FFCC00"
    public static let pEpLightBackgroundHex = "#F2F2F2"
    public static let pEpCellBackgroundHex = "#FFFFFF"
    public static let pEpNavigationBarColor = "#f7f7f7"
    public static let pEpBlueHex = "#007AFF"
    public static let pEpGrayBackgroundResetHex = "#c8c7cc"
    public static let pEpDarkTextHex = "#171717"
    public static let pEpGrayBorderHex = "#B2B2B2"
    public static var pEpGreen = UIColor(hexString: pEpGreenHex)
    public static var pEpDarkGreen = UIColor(hexString: pEpDarkGreenHex)
    public static var pEpRed = UIColor(hexString: pEpRedHex)
    public static var pEpGray = UIColor(hexString: pEpGreyHex)
    public static var pEpYellow = UIColor(hexString: pEpYellowHex)
    public static var pEpNavigation = UIColor(hexString: pEpNavigationBarColor)
    public static var pEpGreyLines = UIColor(hexString: pEpGreyLinesHex)
    public static var pEpGreyButtonLines = UIColor(hexString: pEpGreyButtonLinesHex)
    public static var pEpGreyText = UIColor(hexString: pEpGreyTextHex)
    public static var pEpGrayBorder = UIColor(hexString: pEpGrayBorderHex)
    public static var pEpGreyBackground = UIColor(hexString: pEpGreyBackgroundHex)
    public static var pEpBlue = UIColor(hexString: pEpBlueHex)
    public static var pEpGrayBackgroundReset = UIColor(hexString: pEpGrayBackgroundResetHex)
    public static var pEpCellBackground = UIColor(hexString: pEpCellBackgroundHex)
    public static var pEpDarkText = UIColor(hexString: pEpDarkTextHex)
    public static var pEpTextDark = UIColor.black

    public static let AppleRed =
                UIColor(red: 255/255.0, green: 59/255, blue: 48/255.0, alpha: 1.0)

    /**
     Example use: In trustwords table view cells.
     */
    public static var pEpLightBackground = UIColor(hexString: pEpLightBackgroundHex)

    public convenience init(redInt: Int, greenInt: Int, blueInt: Int, alpha: CGFloat = 1.0) {
        self.init(red: CGFloat(redInt) / 255.0,
                  green: CGFloat(greenInt) / 255.0,
                  blue: CGFloat(blueInt) / 255.0,
                  alpha: alpha)
    }

    public convenience init(hexString: String, alpha: CGFloat = 1.0) {
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

    public convenience init(intValue32: Int, alpha: CGFloat = 1.0) {
        self.init(
            red: CGFloat((intValue32 & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((intValue32 & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat((intValue32 & 0x0000FF) >> 0) / 255.0,
            alpha: alpha
        )
    }
}

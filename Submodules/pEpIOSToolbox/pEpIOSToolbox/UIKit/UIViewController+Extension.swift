//
//  UIViewController+Extension.swift
//  pEpIOSToolbox
//
//  Created by Martín Brude on 02/11/2020.
//  Copyright © 2020 pEp Security SA. All rights reserved.
//

import UIKit

public extension UIViewController {

    /// Indicates if the device is an iPad
    var isIpad : Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }

    /// Indicates if the device is an iPhone
    var isIphone : Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }

    /// Indicates if the device is in Landscape
    var isLandscape: Bool {
        return UIDevice.current.orientation.isLandscape
    }

    /// Indicates if the device is in Portrait
    var isPortrait: Bool {
        return UIDevice.current.orientation.isPortrait
    }
}

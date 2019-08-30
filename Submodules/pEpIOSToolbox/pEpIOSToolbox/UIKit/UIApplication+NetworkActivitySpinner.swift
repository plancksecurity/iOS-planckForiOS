//
//  UIApplication+NetworkActivitySpinner.swift
//  pEpIOSToolbox
//
//  Created by Andreas Buff on 28.08.19.
//  Copyright © 2019 pEp Security SA. All rights reserved.
//

import UIKit

extension UIApplication {

    /// Shows the OS's networkActivitySpinner in the statusbar.
    /// - note: on iPhone X and newer, the status bar does not support this any more, thus the
    ///         spinner is not shown on those devices.
    @available(iOS, deprecated: 13.0, message: "Apple marked it deprecated.")
    static public func showStatusBarNetworkActivitySpinner() {
        GCD.onMain {
            if !UIApplication.shared.isNetworkActivityIndicatorVisible {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
        }
    }

    /// Hides the OS's networkActivitySpinner in the statusbar.
    @available(iOS, deprecated: 13.0, message: "Apple marked it deprecated.")
    static public func hideStatusBarNetworkActivitySpinner() {
        GCD.onMain {
            if UIApplication.shared.isNetworkActivityIndicatorVisible {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        }
    }
}

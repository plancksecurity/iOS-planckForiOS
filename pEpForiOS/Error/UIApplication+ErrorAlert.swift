//
//  UIApplication+ErrorAlert.swift
//  pEp
//
//  Created by Martín Brude on 20/10/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

extension UIApplication {

    /// Indicates if it possible to show an alert.
    /// - Returns: True if possible, false otherwise.
    class public func canShowAlert() -> Bool {
        guard let alert = UIApplication.currentlyVisibleViewController() as? UIAlertController else {
            return true
        }
        return alert.preferredStyle == .alert
    }
}

//
//  UIApplication+Alert.swift
//  pEp
//
//  Created by Martín Brude on 20/10/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

extension UIApplication {

    /// Indicates if an alert is displayed.
    public class var isCurrentlyShowingAlert: Bool {
        guard let alert = UIApplication.currentlyVisibleViewController() as? UIAlertController else {
            return false
        }
        return alert.preferredStyle == .alert
    }
}

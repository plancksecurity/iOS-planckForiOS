//
//  UIApplication+Error.swift
//  pEp
//
//  Created by Martín Brude on 20/10/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

extension UIApplication {
    class public func canShowErrorAlert() -> Bool {
        guard let topMostAlertView =  UIApplication.currentlyVisibleViewController() as? PEPAlertViewController else {
            return true
        }
        return !topMostAlertView.isError
    }
}

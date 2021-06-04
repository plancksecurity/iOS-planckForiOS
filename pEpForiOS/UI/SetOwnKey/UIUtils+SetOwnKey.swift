//
//  UIUtils+SetOwnKey.swift
//  pEp
//
//  Created by Martín Brude on 23/12/20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import pEpIOSToolbox
import UIKit

// MARK: - UIUtils+SetOwnKey

extension UIUtils {

    /// Show Alert view to set own key
    static public func showSetOwnKeyAlertView(callback: @escaping (String?, String?) -> Void) {
        DispatchQueue.main.async {
            guard let alertViewController = PEPAlertWithTextViewsViewController.getSetOwnKeyAlertView(callback: callback) else {
                Log.shared.errorAndCrash("Cant instanciate Set Own Key Alert View")
                return
            }
            let currentlyVisibleViewController = UIApplication.currentlyVisibleViewController()
            alertViewController.modalPresentationStyle = .overFullScreen
            alertViewController.modalTransitionStyle = .crossDissolve
            currentlyVisibleViewController.present(alertViewController, animated: true)
        }
    }
}

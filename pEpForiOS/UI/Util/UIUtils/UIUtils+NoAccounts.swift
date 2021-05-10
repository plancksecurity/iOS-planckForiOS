//
//  UIUtils+NoAccounts.swift
//  pEp
//
//  Created by Martín Brude on 7/5/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import Foundation
import pEpIOSToolbox

extension UIUtils {

    /// Modally presents a "No Activated Account ViewController"
    static public func presentNoActivatedAccountView() {
        DispatchQueue.main.async {
            let settingsStoryboard = UIStoryboard(name: Constants.settingsStoryboard, bundle: nil)
            guard let noActivatedAccountViewController = settingsStoryboard.instantiateViewController(withIdentifier: NoActivatedAccountViewController.storyboardId) as? NoActivatedAccountViewController else {
                Log.shared.errorAndCrash("NoActivatedAccountViewController is not available!")
                return
            }
            noActivatedAccountViewController.hidesBottomBarWhenPushed = true
            let presenterVc = UIApplication.currentlyVisibleViewController()
            presenterVc.navigationController?.pushViewController(noActivatedAccountViewController, animated: true)
        }
    }
}



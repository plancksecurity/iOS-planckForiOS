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

    /// Modally presents a "No Activated Account ViewController"
    static public func presentSetupAccount(loginDelegate: LoginViewControllerDelegate) {
        DispatchQueue.main.async {
            let accountCreationStoryboard = UIStoryboard(name: Constants.accountCreationStoryboard, bundle: nil)
            guard let accountCreationVC = accountCreationStoryboard.instantiateViewController(withIdentifier: AccountTypeSelectorViewController.storyboardId) as? AccountTypeSelectorViewController else {
                Log.shared.errorAndCrash("AccountTypeSelectorViewController is not available!")
                return
            }
            accountCreationVC.hidesBottomBarWhenPushed = true
            let presenterVc = UIApplication.currentlyVisibleViewController()

            let nav = UINavigationController(rootViewController: accountCreationVC)

            nav.modalTransitionStyle = .coverVertical
            nav.modalPresentationStyle = .fullScreen
            accountCreationVC.loginDelegate = loginDelegate

            presenterVc.present(nav, animated: true, completion: nil)
        }
    }
}

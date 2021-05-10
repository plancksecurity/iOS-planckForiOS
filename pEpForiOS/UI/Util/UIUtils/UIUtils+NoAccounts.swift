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
        let settingsStoryboard = UIStoryboard(name: Constants.settingsStoryboard, bundle: nil)
        guard let noActivatedAccountViewController = settingsStoryboard.instantiateViewController(withIdentifier: NoActivatedAccountViewController.storyboardId) as? NoActivatedAccountViewController else {
            Log.shared.errorAndCrash("NoActivatedAccountViewController is not available!")
                return
        }
        noActivatedAccountViewController.hidesBottomBarWhenPushed = false
        noActivatedAccountViewController.modalPresentationStyle = .fullScreen
        noActivatedAccountViewController.modalTransitionStyle = .coverVertical
        let navigationController = UINavigationController(rootViewController: noActivatedAccountViewController)
//        if let toolbar = navigationController.toolbar {
//            vc.modalPresentationStyle = .popover
//            vc.preferredContentSize = CGSize(width: toolbar.frame.width
//                                                - 16,
//                                             height: 420)
//            vc.popoverPresentationController?.sourceView = vc.view
//            let frame = CGRect(x: toolbar.frame.origin.x,
//                               y: toolbar.frame.origin.y - 10,
//                               width: toolbar.frame.width,
//                               height: toolbar.frame.height)
//            vc.popoverPresentationController?.sourceRect = frame
//        }
        UIUtils.show(navigationController: navigationController)
    }
}

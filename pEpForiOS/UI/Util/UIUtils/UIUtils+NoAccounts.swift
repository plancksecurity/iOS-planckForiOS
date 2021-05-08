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
    /// Modally presents a "Drafts Preview"
    static public func presentNoActivatedAccountView() {
        let sb = UIStoryboard(name: Constants.settingsStoryboard, bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: NoActivatedAccountViewController.storyboardId) as? NoActivatedAccountViewController else {
            Log.shared.errorAndCrash("NoActivatedAccountViewController is not available!")
                return
        }
        vc.hidesBottomBarWhenPushed = false
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .coverVertical
        let navigationController =
            UINavigationController(rootViewController: vc)
        if let toolbar = navigationController.toolbar {
            vc.modalPresentationStyle = .popover
            vc.preferredContentSize = CGSize(width: toolbar.frame.width
                                                - 16,
                                             height: 420)
            vc.popoverPresentationController?.sourceView = vc.view
            let frame = CGRect(x: toolbar.frame.origin.x,
                               y: toolbar.frame.origin.y - 10,
                               width: toolbar.frame.width,
                               height: toolbar.frame.height)
            vc.popoverPresentationController?.sourceRect = frame
        }
        UIUtils.show(navigationController: navigationController)
    }
}

//
//  PrimarySplitViewController.swift
//  pEp
//
//  Created by Borja González de Pablo on 23/05/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit
import pEpIOSToolbox

//!!!: The concept is very dirty. PrimarySplitViewController should not be aware of EmailListViewController.
// According to //XAVIER, the implementation will change to be generic (emilaiVC independent) with the new SplitViewController concept which is WIP.
class PrimarySplitViewController: UISplitViewController, UISplitViewControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()

        self.delegate = self
        preferredDisplayMode = .allVisible
    }

    func splitViewController(_ splitViewController: UISplitViewController,
                             collapseSecondary secondaryViewController:UIViewController,
                             onto primaryViewController:UIViewController) -> Bool {
        guard
            let navigationController = secondaryViewController as? UINavigationController,
            navigationController.rootViewController is EmailViewController
            else {
                return true
        }

        return false
    }

    func splitViewController(_ splitViewController: UISplitViewController,
                             separateSecondaryFrom primaryViewController: UIViewController)
        -> UIViewController? {
            guard
                let navigationController =
                splitViewController.viewControllers.first as? UINavigationController,
                let secondaryNavigationController =
                navigationController.topViewController as? UINavigationController,
                secondaryNavigationController.topViewController is EmailViewController
                else {
                    let storyboard = UIStoryboard(
                        name: UIStoryboard.noSelectionStoryBoard,
                        bundle: nil)
                    let vc = storyboard.instantiateViewController(
                        withIdentifier: UIStoryboard.nothingSelectedViewController)
                    return vc
            }
            return secondaryNavigationController
    }
}

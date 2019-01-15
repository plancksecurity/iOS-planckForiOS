//
//  PrimarySplitViewController.swift
//  pEp
//
//  Created by Borja González de Pablo on 23/05/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

class PrimarySplitViewController: UISplitViewController, UISplitViewControllerDelegate {
    override func viewDidLoad() {
        self.delegate = self
        preferredDisplayMode = .allVisible
    }

    func splitViewController(_ splitViewController: UISplitViewController,
                             collapseSecondary secondaryViewController:UIViewController,
                             onto primaryViewController:UIViewController) -> Bool {
        guard let navigationController = secondaryViewController as? UINavigationController,
            navigationController.rootViewController is EmailViewController ||
                navigationController.rootViewController is ThreadViewController
            else {
                return true
        }

        return false
    }

    func splitViewController(_ splitViewController: UISplitViewController,
                             separateSecondaryFrom primaryViewController: UIViewController)
        -> UIViewController? {

            guard let navigationController =
                    splitViewController.viewControllers.first as? UINavigationController,
                let secondaryNavigationController =
                    navigationController.topViewController as? UINavigationController,
                secondaryNavigationController.topViewController is EmailViewController ||
                    secondaryNavigationController.topViewController is ThreadViewController
                else {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "noMessagesViewController")
                    return vc
            }
            return secondaryNavigationController
    }

    func splitViewController(_ svc: UISplitViewController, willChangeTo displayMode: UISplitViewControllerDisplayMode) {


        guard let nav = viewControllers.last as? UINavigationController,
            let emailViewController = nav.rootViewController as? EmailViewController else {
                return
        }

        emailViewController.splitViewController(willChangeTo: displayMode)
    }
}

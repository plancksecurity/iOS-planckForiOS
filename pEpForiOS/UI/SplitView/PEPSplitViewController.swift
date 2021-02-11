//
//  PEPSplitViewController.swift
//  pEp
//
//  Created by Borja González de Pablo on 23/05/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit
import pEpIOSToolbox

class PEPSplitViewController: UISplitViewController, UISplitViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        preferredDisplayMode = .allVisible
    }

    func splitViewController(_ splitViewController: UISplitViewController,
                             collapseSecondary secondaryViewController:UIViewController,
                             onto primaryViewController:UIViewController) -> Bool {
        if let navigationController = secondaryViewController as? UINavigationController,
            let top = navigationController.topViewController, top.collapsedBehavior == .needed,
            let primaryNavigationController = primaryViewController as? UINavigationController {
            navigationController.popViewController(animated: false)
            primaryNavigationController.pushViewController(top, animated: false)
            if let vc = top as? SplitViewHandlingProtocol {
                vc.splitViewControllerWill(splitViewController: self, newStatus: .collapse)
            }
        }
        return true
    }

    func splitViewController(_ splitViewController: UISplitViewController,
                             separateSecondaryFrom primaryViewController: UIViewController)
        -> UIViewController? {
            let navigationController = UINavigationController()
            guard let primaryView = primaryViewController as? UINavigationController else {
                Log.shared.errorAndCrash(message: "root view is not nav Controller?")
                return nil
            }
            if let topView = primaryView.topViewController, topView.separatedBehavior == .detail {
                primaryView.popViewController(animated: false)
                navigationController.pushViewController(topView, animated: false)
                if let vc = topView as? SplitViewHandlingProtocol {
                    vc.splitViewControllerWill(splitViewController: self, newStatus: .separate)
                }
            } else {
                let storyboard = UIStoryboard(
                    name: UIStoryboard.noSelectionStoryBoard,
                    bundle: nil)
                let vc = storyboard.instantiateViewController(
                    withIdentifier: UIStoryboard.nothingSelectedViewController)
                navigationController.pushViewController(vc, animated: false)

            }
        return navigationController
    }
    
    func splitViewController(_ splitViewController: UISplitViewController,
                             showDetail vc: UIViewController, sender: Any?) -> Bool {
        if !onlySplitViewMasterIsShown {
            //apple docs say detailView will be always in the position 1 of the .viewcontrollers array
            let detail = 1
            guard splitViewController.viewControllers.count == 2,
                let controller = splitViewController.viewControllers[detail] as? UINavigationController else {
                return false
            }
            controller.viewControllers = [vc]
            return true
        }
        return false
    }
}

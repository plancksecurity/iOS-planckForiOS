//
//  UIApplication+NavigationStack.swift
//  pEpIOSToolbox
//
//  Created by Andreas Buff on 21.02.20.
//  Copyright © 2020 pEp Security SA. All rights reserved.
//

import UIKit

// MARK: - UIApplication+NavigationStack

extension UIApplication {

    /// - returns: The currently visible view controller if any, nil otherwize. Child ViewControllers are ignored.
    class public func currentlyVisibleViewController(inNavigationStackOf viewController: UIViewController? = nil) -> UIViewController {
        return topViewController(inNavigationStackOf: viewController ?? UIApplication.shared.keyWindow?.rootViewController)
    }

    /// - Parameter viewController: ViewController whichs navigation stack's top VC should be found
    /// - returns: The view controller at the top of the navigation stack.
    class private func topViewController(inNavigationStackOf viewController: UIViewController?) -> UIViewController {
        guard let vc = viewController else {
            Log.shared.errorAndCrash("No VC. Probably unexpected.")
            return UIViewController()
        }
        if let nav = vc as? UINavigationController {
            return topViewController(inNavigationStackOf: nav.topViewController)
        } else if let tab = vc as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(inNavigationStackOf: selected)
        } else if let splitVC = vc as? UISplitViewController {
            guard let primaryVc = splitVC.viewControllers.first else {
                Log.shared.errorAndCrash("Splitview without Primary VC?")
                return UIViewController()
            }
            return topViewController(inNavigationStackOf: primaryVc)
        } else if let presented = vc.presentedViewController {
            return topViewController(inNavigationStackOf: presented)
        } else if let searchVc = vc as? UISearchController {
            //this situation happens when searchBar is in focus.
            //it's needed to select the viewController that presents the searchbar
            //as a topViewController.
            guard let searchVCPresenter = searchVc.presentingViewController else {
                Log.shared.errorAndCrash("searchVC not found")
                return UIViewController()
            }
            return searchVCPresenter
        }
        return vc
    }
}

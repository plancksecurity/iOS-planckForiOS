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

    /// - returns: The view controller at the top of the navigation stack.
    class public func topViewController(
        inNavigationStackOf viewController: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        guard let vc = viewController else {
            Log.shared.errorAndCrash("No VC. Probably unexpected.")
            return nil
        }
        if let nav = vc as? UINavigationController {
            return topViewController(inNavigationStackOf: nav.topViewController)
        } else if let tab = vc as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(inNavigationStackOf: selected)
        } else if let splitVC = viewController as? UISplitViewController {
            guard let vc = splitVC.viewControllers.first else {
                Log.shared.errorAndCrash("Splitview without Primary VC?")
                return nil
            }
            return topViewController(inNavigationStackOf: vc)
        } else if let presented = vc.presentedViewController {
            return topViewController(inNavigationStackOf: presented)
        }
        return vc
    }
}

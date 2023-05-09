//
//  UIUtils+ActivityIndecator.swift
//  pEp
//
//  Created by Andreas Buff on 13.03.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import PlanckToolbox

// MARK: - UIUtils+ActivityIndicator

extension UIUtils {

    /// Show simple UIActivityIndicatorView in midle of current view
    ///
    /// - Returns: UIActivityIndicatorView. Useful to hold for removing from super view
    @discardableResult
    static public func showActivityIndicator(viewController: UIViewController? = nil) -> UIActivityIndicatorView {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.startAnimating()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        var presenterVc = UIApplication.currentlyVisibleViewController()
        if presenterVc is PEPAlertViewController, let vc = viewController {
            presenterVc = vc
        }
        let view: UIView = presenterVc.view
        view.addSubview(activityIndicator)
        NSLayoutConstraint(item: activityIndicator,
                           attribute: .centerX,
                           relatedBy: .equal,
                           toItem: view,
                           attribute: .centerX,
                           multiplier: 1,
                           constant: 0).isActive = true

        NSLayoutConstraint(item: activityIndicator,
                           attribute: .centerY,
                           relatedBy: .equal,
                           toItem: view,
                           attribute: .centerY,
                           multiplier: 1,
                           constant: 0).isActive = true

        return activityIndicator
    }
}

//
//  UIUtils+ActivityIndecator.swift
//  pEp
//
//  Created by Andreas Buff on 13.03.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import pEpIOSToolbox

// MARK: - UIUtils+ActivityIndecator

extension UIUtils {

    /// Show simple UIActivityIndicatorView in midle of current view
    ///
    /// - Returns: UIActivityIndicatorView. Useful to hold for removing from super view
    @discardableResult
    static public func showActivityIndicator() -> UIActivityIndicatorView {
        let activityIndicator = UIActivityIndicatorView(style: .gray)
        activityIndicator.startAnimating()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        guard let presenterVc = UIApplication.currentlyVisibleViewController() else {
            Log.shared.errorAndCrash("No VC")
            return activityIndicator
        }
        let view: UIView = presenterVc.view
        view.addSubview(activityIndicator)

        NSLayoutConstraint(item: activityIndicator,
                           attribute: .centerX,
                           relatedBy: .equal,
                           toItem: view,
                           attribute: .centerX, multiplier: 1,
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

//
//  UIView+Util.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 10.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

/**
 A piece of data for tracking the "busyness" of a view.
 */
struct ViewBusyState {
    let activityView: UIActivityIndicatorView
}

extension UIView {
    func dumpConstraints(axis: UILayoutConstraintAxis) {
        let constrs = constraintsAffectingLayout(for: axis)
        if constrs.isEmpty {
            print("no constraints")
        }
        for con in constrs {
            print("\(con)")
        }
    }

    /**
     Marks the view as busy, e.g. by adding some spinning animation view.
     */
    func displayAsBusy() -> ViewBusyState {
        let width: CGFloat = 64
        let activityView = UIActivityIndicatorView()
        activityView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityView)
        activityView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        activityView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        activityView.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor).isActive = true
        activityView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor).isActive = true
        activityView.heightAnchor.constraint(
            equalTo: activityView.widthAnchor, multiplier: 1).isActive = true
        activityView.widthAnchor.constraint(greaterThanOrEqualToConstant: width).isActive = true
        activityView.startAnimating()
        return ViewBusyState(activityView: activityView)
    }

    /**
     Marks the given view as not busy anymore.
     */
    func stopDisplayingAsBusy(viewBusyState: ViewBusyState) {
        viewBusyState.activityView.removeFromSuperview()
    }
}

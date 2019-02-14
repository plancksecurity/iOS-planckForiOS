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
public struct ViewBusyState {
    let views: [UIView]
}

extension UIView {
    func dumpConstraints(axis: NSLayoutConstraint.Axis) {
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
    public func displayAsBusy() -> ViewBusyState {
        let darkView = UIView()
        darkView.translatesAutoresizingMaskIntoConstraints = false
        darkView.backgroundColor = .black
        darkView.alpha = 0.5
        addSubview(darkView)
        darkView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        darkView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        darkView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        darkView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true

        let activityView = UIActivityIndicatorView()
        activityView.activityIndicatorViewStyle = .whiteLarge
        activityView.translatesAutoresizingMaskIntoConstraints = false
        darkView.addSubview(activityView)
        activityView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        activityView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        activityView.startAnimating()
        return ViewBusyState(views: [darkView])
    }

    /**
     Marks the given view as not busy anymore.
     */
    public func stopDisplayingAsBusy(viewBusyState: ViewBusyState) {
        for v in viewBusyState.views {
            v.removeFromSuperview()
        }
    }
}

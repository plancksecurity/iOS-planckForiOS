//
//  UIView+Autolayout.swift
//  pEp
//
//  Created by Andreas Buff on 09.03.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

extension UIView {
    /// Sets up constraints to always stay the same size as the superview.
    public func fullSizeInSuperView() {
        guard let superview = self.superview else {
            Log.shared.errorAndCrash("No superview")
            return
        }

        self.translatesAutoresizingMaskIntoConstraints = false
        superview.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "H:|-0-[subview]-0-|",
            options: .directionLeadingToTrailing,
            metrics: nil,
            views: ["subview": self]))
        superview.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "V:|-0-[subview]-0-|",
            options: .directionLeadingToTrailing,
            metrics: nil,
            views: ["subview": self]))
    }
}

//
//  UIView+Autolayout.swift
//  pEp
//
//  Created by Andreas Buff on 09.03.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit
import pEpUtilities

extension UIView {
    /// Sets up constraints to always stay the same size as the superview.
    func fullSizeInSuperView() {
        guard let superview = self.superview else {
            Logger.frontendLogger.errorAndCrash("No superview")
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

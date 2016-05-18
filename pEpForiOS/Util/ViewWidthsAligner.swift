//
//  ViewWidthsAligner.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 18/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

/**
 Aligns a couple of given views by their width. Typically called from `viewDidAppear:`
 */
public class ViewWidthsAligner {
    var addedConstraints: [NSLayoutConstraint] = []

    public func alignViews(viewsToAlign: [UIView], parentView: UIView) {
        var previousView: UIView? = nil
        for v in viewsToAlign {
            if let v1 = previousView {
                let c = NSLayoutConstraint.init(item: v1, attribute: .Width, relatedBy: .Equal,
                                                toItem: v, attribute: .Width, multiplier: 1.0,
                                                constant: 0.0)
                addedConstraints.append(c)
                parentView.addConstraint(c)
            }
            previousView = v
        }
    }
}
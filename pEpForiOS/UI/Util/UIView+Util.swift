//
//  UIView+Util.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 10.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

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
}

//
//  UIViewController+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 17/02/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    func showPepRating(pEpRating: PEP_rating?, pEpProtection: Bool = true) -> UIView? {
        // icon
        if let img = pEpRating?.pepColor().statusIcon(enabled: pEpProtection) {
            let v = UIImageView(image: img)
            navigationItem.titleView = v
            v.isUserInteractionEnabled = true
            return v
        } else {
            navigationItem.titleView = nil
            return nil
        }
    }
}

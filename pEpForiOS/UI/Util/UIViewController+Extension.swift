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
        if let img = pEpRating?.pEpColor().statusIcon(enabled: pEpProtection) {
            // according to apple's design guidelines ('Hit Targets'):
            // https://developer.apple.com/design/tips/
            let officialMinimumDimension: CGFloat = 44

            let newMinimumWidth = max(officialMinimumDimension / 2, img.size.width)
            let img2 = img.resized(newWidth: newMinimumWidth)
            let v = UIImageView(image: img2)
            v.contentMode = .center // DON'T stretch the image, leave it at original size

            // try to make the hit area of the icon a minimum of 44x44
            let minimumDesiredDimension: CGFloat = min(
                officialMinimumDimension,
                navigationController?.navigationBar.frame.size.height ?? officialMinimumDimension)
            v.bounds.size = CGSize(width: minimumDesiredDimension, height: minimumDesiredDimension)

            navigationItem.titleView = v
            v.isUserInteractionEnabled = true
            return v
        } else {
            navigationItem.titleView = nil
            return nil
        }
    }
}

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
        setEmailDisplayColors()
        
        // icon
        navigationItem.title = nil
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

    func setNoColor() {
        navigationController?.navigationBar.barTintColor = nil
        navigationController?.toolbar.barTintColor = nil
        navigationController?.navigationItem.rightBarButtonItem = nil
        navigationController?.navigationBar.backgroundColor = nil
    }

    func setEmailDisplayColors() {
        setNoColor()
        navigationController?.navigationBar.titleTextAttributes =
            [NSForegroundColorAttributeName: UIColor.black]
        navigationController?.navigationBar.tintColor = UIColor.pEpGreen
        navigationController?.toolbar.tintColor = UIColor.pEpGreen
    }

    func setDefaultColors() {
        navigationController?.navigationBar.barTintColor =
            UINavigationBar.appearance().barTintColor
        navigationController?.toolbar.barTintColor =
            UIToolbar.appearance().barTintColor
        navigationController?.navigationBar.backgroundColor =
            UINavigationBar.appearance().backgroundColor

        navigationController?.navigationBar.tintColor = UINavigationBar.appearance().tintColor
        navigationController?.navigationBar.titleTextAttributes =
            UINavigationBar.appearance().titleTextAttributes
        navigationController?.toolbar.tintColor = UIToolbar.appearance().tintColor
    }


}

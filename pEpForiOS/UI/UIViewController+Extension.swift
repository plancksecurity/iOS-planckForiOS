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
    func showPepRating(pEpRating: PEP_rating?) {
        setNoColor()

        // icon
        navigationItem.title = nil
        if let img = pEpRating?.pepColor().statusIcon() {
            navigationItem.titleView = UIImageView(image: img)
        } else {
            navigationItem.titleView = nil
        }
    }

    func setNoColor() {
        navigationController?.navigationBar.barTintColor = nil
        navigationController?.toolbar.barTintColor = nil
        navigationController?.navigationItem.rightBarButtonItem = nil
        navigationController?.navigationBar.backgroundColor = nil
    }

    func setDefaultColors() {
        navigationController?.navigationBar.barTintColor =
            UINavigationBar.appearance().barTintColor
        navigationController?.toolbar.barTintColor =
            UIToolbar.appearance().barTintColor
        navigationController?.navigationBar.backgroundColor =
            UINavigationBar.appearance().backgroundColor
    }
}

//
//  UIViewController+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 17/02/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

class NavigationBarData {
    var handledDefault: Bool = false
    var defaultNavigationBarColor: UIColor?
    var defaultToolBarColor: UIColor?

    static var sharedData: NavigationBarData = {
        return NavigationBarData()
    }()

    func handleDefaults(navigationController: UINavigationController?) {
        if !handledDefault {
            handledDefault = true
            defaultNavigationBarColor = navigationController?.navigationBar.barTintColor
            defaultToolBarColor = navigationController?.toolbar.barTintColor
        }
    }
}

extension UIViewController {
    func showPepRating(pEpRating: PEP_rating?) {
        NavigationBarData.sharedData.handleDefaults(navigationController: navigationController)

        // color
        if let color = pEpRating?.uiColor() {
            navigationController?.navigationBar.barTintColor = color
            navigationController?.toolbar.barTintColor = color
        } else {
            setDefaultBarColors()
        }

        // icon
        navigationItem.title = nil
        if let img = pEpRating?.pepColor().statusIcon() {
            navigationItem.titleView = UIImageView(image: img)
        } else {
            navigationItem.titleView = nil
        }
    }

    func setDefaultBarColors() {
        navigationController?.navigationBar.barTintColor =
            NavigationBarData.sharedData.defaultNavigationBarColor
        navigationController?.toolbar.barTintColor =
            NavigationBarData.sharedData.defaultToolBarColor
        navigationController?.navigationItem.rightBarButtonItem = nil
    }
}

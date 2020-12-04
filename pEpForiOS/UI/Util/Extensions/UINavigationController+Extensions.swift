//
//  UINavigationController+Extensions.swift
//  pEpForiOS
//
//  Created by Andreas Buff on 23.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

extension UINavigationController {

    public var rootViewController : UIViewController? {
        return viewControllers.first
    }
}

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

    /// Retrieve the first view controller of the type passed by parameter.
    /// - Parameter class: The class of the view controller to find.
    /// - Returns: The found VC, nil if not found.
    public func child<T:UIViewController>(ofType class: T.Type) -> T? {
        return viewControllers.filter { $0 is T } .first as? T
    }
}

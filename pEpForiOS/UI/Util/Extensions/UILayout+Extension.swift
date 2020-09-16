//
//  UILayout+Extension.swift
//  pEp
//
//  Created by Martin Brude on 07/07/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

extension NSLayoutConstraint {

    /// Returns the constraint sender with the passed priority.
    ///
    /// - Parameter priority: The priority to be set.
    /// - Returns: The sended constraint adjusted with the new priority.
    public func usingPriority(_ priority: UILayoutPriority) -> NSLayoutConstraint {
        self.priority = priority
        return self
    }
}

extension UILayoutPriority {

    /// Creates a priority which is almost required, but not 100%.
    public static var almostRequired: UILayoutPriority {
        return UILayoutPriority(rawValue: 999)
    }

    /// Creates a priority which is not required at all.
    public static var notRequired: UILayoutPriority {
        return UILayoutPriority(rawValue: 0)
    }
}

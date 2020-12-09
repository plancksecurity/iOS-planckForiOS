//
//  UIView+FindSuperview.swift
//  pEpIOSToolbox
//
//  Created by Martín Brude on 9/12/20.
//  Copyright © 2020 pEp Security SA. All rights reserved.
//

import Foundation
import UIKit

extension UIView {

    /// Find and retrieves the first superview that is an instance of class passed by parameter.
    ///
    /// - Parameter ofClass: The target class.
    /// - Returns: If found, returns the view. Nil otherwise.
    public func superviewOfClass<T>(ofClass: T.Type) -> T? {
        var currentView: UIView? = self
        while currentView != nil {
            if currentView is T {
                break
            } else {
                currentView = currentView?.superview
            }
        }
        return currentView as? T
    }
}

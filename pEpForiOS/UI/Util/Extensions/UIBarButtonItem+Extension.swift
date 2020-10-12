//
//  UIBarButtonItem+Extension.swift
//  pEp
//
//  Created by Xavier Algarra on 11/07/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

extension UIBarButtonItem {
    public static func getFilterOnOffButton(action: Selector, target: Any) -> UIBarButtonItem {
        let img = UIImage(named: "unread-icon")
        return getButton(image: img, action: action, target: target)
    }
    public static func getPEPButton(action: Selector, target: Any) -> UIBarButtonItem {
        let img = UIImage(named: "icon-settings")
        return getButton(image: img, action: action, target: target)
    }
    public static func getNextButton(action: Selector, target: Any) -> UIBarButtonItem {
        let img = UIImage(named: "chevron-icon-right")
        return getButton(image: img, action: action, target: target)
    }
    public static func getPreviousButton(action: Selector, target: Any) -> UIBarButtonItem {
        let img = UIImage(named: "chevron-icon-left")
        return getButton(image: img, action: action, target: target)
    }
    private static func getButton(image: UIImage?, action: Selector, target: Any) -> UIBarButtonItem {
        return UIBarButtonItem(image: image, style: .plain, target: target, action: action)
    }
}

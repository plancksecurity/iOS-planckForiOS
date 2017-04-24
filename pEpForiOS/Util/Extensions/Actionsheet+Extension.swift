//
//  Actionsheet+Extension.swift
//  pEpForiOS
//
//  Created by Yves Landert on 08.12.16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import MessageModel

public extension UIAlertController {
    
    public func action(_ title: String, _ style: UIAlertActionStyle = .default, _ closure: Tasks.simple? = nil) ->  UIAlertAction {
        return UIAlertAction(title: title.localized, style: style) { (action) in
            if closure != nil { closure!() }
        }
    }
}

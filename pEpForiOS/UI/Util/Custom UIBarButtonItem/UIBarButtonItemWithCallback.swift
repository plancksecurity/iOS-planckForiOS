//
//  UIBarButtonItemWithCallback.swift
//  pEp
//
//  Created by Martín Brude on 21/7/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import Foundation

/// UIBarButtonItem that may use a callback instead of a selector, which gives more versatility.
///
/// Usage example:
///       let myButton = UIBarButtonItemWithCallback(title: "button title", style: .plain) { item in
///         /// your code here
///       }
///
class UIBarButtonItemWithCallback: UIBarButtonItem {
    typealias ActionHandler = (UIBarButtonItem) -> Void

    private var actionHandler: ActionHandler?

    convenience init(title: String?, style: UIBarButtonItem.Style, actionHandler: ActionHandler?) {
        self.init(title: title, style: style, target: nil, action: #selector(barButtonItemPressed(sender:)))
        target = self
        self.actionHandler = actionHandler
    }

    @objc func barButtonItemPressed(sender: UIBarButtonItem) {
        actionHandler?(sender)
    }
}

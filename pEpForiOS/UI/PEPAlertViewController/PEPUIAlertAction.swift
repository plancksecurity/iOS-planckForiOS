//
//  PEPUIAlertAction.swift
//  pEp
//
//  Created by Alejandro Gelos on 22/08/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

/// An UIAlertAction that hold the handler block and can execute it
final class PEPUIAlertAction: UIAlertAction {

    private var handler: ((UIAlertAction) -> Void)?

    static func with(title: String?,
                     style: UIAlertAction.Style,
                     handler: ((UIAlertAction) -> Void)? = nil) -> PEPUIAlertAction {
        let action = PEPUIAlertAction(title: title, style: style, handler: handler)
        action.handler = handler
        return action
    }

    func execute() {
        handler?(self)
    }
}

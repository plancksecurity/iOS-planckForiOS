//
//  PEPUIAlertAction.swift
//  pEp
//
//  Created by Alejandro Gelos on 22/08/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

final class PEPUIAlertAction {

    private var handler: ((PEPUIAlertAction) -> Void)?

    let style: UIColor
    let title: String?

    init(title: String?,
         style: UIColor,
         handler: ((PEPUIAlertAction) -> Void)? = nil) {

        self.title = title
        self.style = style
        self.handler = handler
    }

    /// Execute PEPUIAlertAction block
    func execute() {
        handler?(self)
    }
}

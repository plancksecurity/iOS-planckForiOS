//
//  PlanckUIAlertAction.swift
//  pEp
//
//  Created by Alejandro Gelos on 22/08/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

final class PlanckUIAlertAction {

    private var handler: ((PlanckUIAlertAction) -> Void)?

    let style: UIColor
    let title: String?

    init(title: String?,
         style: UIColor,
         handler: ((PlanckUIAlertAction) -> Void)? = nil) {

        self.title = title
        self.style = style
        self.handler = handler
    }

    /// Execute PlanckUIAlertAction block
    func execute() {
        handler?(self)
    }
}

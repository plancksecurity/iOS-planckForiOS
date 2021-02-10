//
//  UIUtils.swift
//  pEp
//pde
//  Created by Andreas Buff on 29.11.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit
import ContactsUI

#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

#if EXT_SHARE
import PEPIOSToolboxForAppExtensions
#else
import pEpIOSToolbox
#endif

class UIUtils {
    /// Shows the navigation controller passed by parameter
    /// - Parameter navigationController: The Navigation Controller to present.
    public static func show(navigationController: UINavigationController) {
        let presenterVc = UIApplication.currentlyVisibleViewController()
        presenterVc.present(navigationController, animated: true)
    }

}

//
//  UIUtils.swift
//  pEp
//
//  Created by Andreas Buff on 29.11.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit
import ContactsUI

#if EXT_SHARE
import MessageModelForAppExtensions
import pEpIOSToolboxForExtensions
#else
import MessageModel
import pEpIOSToolbox
#endif
import SwiftMessages

class UIUtils { 

    public static private(set) var swiftMessages = UIUtils.getSwiftMessagesConfigured()

    private static func getSwiftMessagesConfigured() -> SwiftMessages {
        let instance = SwiftMessages.sharedInstance
        instance.pauseBetweenMessages = 1.0
        var config = SwiftMessages.Config()
        config.duration = .seconds(seconds: 5)
        instance.defaultConfig = config
        return instance
    }

    /// Shows the navigation controller passed by parameter
    /// - Parameter navigationController: The Navigation Controller to present.
    public static func show(navigationController: UINavigationController) {
        let presenterVc = UIApplication.currentlyVisibleViewController()
        presenterVc.present(navigationController, animated: true)
    }
}

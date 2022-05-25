//
//  AppDelegate+PredeployedAccounts.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 24.05.22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation

import pEpIOSToolbox

private typealias SettingsDict = [String:Any]

extension AppDelegate {
    /// Checks for predeployed accounts, and acts on them.
    ///
    /// - Returns: In the case of error, a localized error message, that can be shown
    /// in an error view later (once the first view controller is active).
    public func predeployAccounts() -> String? {
        let predeployer: MDMPredeployedProtocol = MDMPredeployed()
        do {
            try predeployer.predeployAccounts()
            return nil
        } catch let error as MDMPredeployedError {
            return "\(error)"
        } catch {
            return NSLocalizedString("Unknown Error", comment: "MDM Unknown Error")
        }
    }

    public func predeployAccounts(errorMessage: String) {
        let titleString = NSLocalizedString("MDM Predeployment Error",
                                            comment: "MDM Predeployment Error Title")
        UIUtils.showAlertWithOnlyPositiveButton(title: titleString, message: errorMessage)
    }
}

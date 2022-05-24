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
    public func predeployAccounts() {
        func showError(message: String) {
            let titleString = NSLocalizedString("MDM Predeployment Error",
                                                comment: "MDM Predeployment Error Title")
            UIUtils.showAlertWithOnlyPositiveButton(title: titleString, message: message)
        }

        let predeployer: MDMPredeployedProtocol = MDMPredeployed()
        do {
            try predeployer.predeployAccounts()
        } catch let error as MDMPredeployedError {
            showError(message: "\(error)")
        } catch {
            let message = NSLocalizedString("Unknown Error", comment: "MDM Unknown Error")
            showError(message: message)
        }
    }
}

//
//  UIUtils+Settings.swift
//  pEp
//
//  Created by Andreas Buff on 13.03.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import pEpIOSToolbox

// MARK: - UIUtils+Settings

extension UIUtils {

    static public func showSettings() {
        guard let vc = UIStoryboard.init(name: "Settings", bundle: Bundle.main).instantiateViewController(withIdentifier: SettingsTableViewController.storyboardId) as? SettingsTableViewController else {
            Log.shared.errorAndCrash("No controller")
            return
        }
        let presenterVc = UIApplication.currentlyVisibleViewController()
        presenterVc.navigationController?.pushViewController(vc, animated: true)
    }

    /// Indicate if MDM has been deployed.
    static public func hasBeenMDMDeployed(appSettings: AppSettingsProtocol) -> Bool {
        guard let appSetting = appSettings as? MDMAppSettingsProtocol, appSetting.hasBeenMDMDeployed else {
            return false
        }
        return true
    }
}

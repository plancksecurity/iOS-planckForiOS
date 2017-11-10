//
//  BaseTableViewController.swift
//  pEpForiOS
//
//  Created by buff on 23.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

class BaseTableViewController: UITableViewController {
    private var _appConfig: AppConfig?

    var originalTitleView: String?

    var appConfig: AppConfig {
        get {
            guard let theAC = _appConfig else {
                Log.shared.errorAndCrash(component: #function, errorString: "No appConfig?")

                // We have no config. Return nonsense.
                return AppConfig(mySelfer: self,
                    messageSyncService: MessageSyncService(
                        sleepTimeInSeconds: 2, backgrounder: nil, mySelfer: nil), errorHandler: ErrHandler())
            }
            return theAC
        }
        set {
            _appConfig = newValue
            didSetAppConfig()
        }
    }

    func didSetAppConfig() {
        // do nothing. Meant to be overridden by subclasses that require this information
    }
}

extension BaseTableViewController: KickOffMySelfProtocol {
    func startMySelf() {
        Log.shared.errorAndCrash(component: #function, errorString: "No appConfig?")
    }
}

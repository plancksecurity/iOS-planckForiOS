//
//  TableViewControllerBase.swift
//  pEpForiOS
//
//  Created by buff on 23.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

class TableViewControllerBase: UITableViewController {
    private var _appConfig: AppConfig?

    var originalTitleView: String?

    var appConfig: AppConfig {
        get {
            guard let theAC = _appConfig else {
                Log.shared.errorAndCrash(component: #function, errorString: "No appConfig?")

                // The app should crash in the line before, so this never gets actually
                // executed. Just here to make it compile.
                return AppConfig(
                    session: PEPSession(),
                    mySelfer: self,
                    messageSyncService: MessageSyncService(
                        sleepTimeInSeconds: 2, backgrounder: nil, mySelfer: nil))
            }
            return theAC
        }
        set {
            _appConfig = newValue
            didSetAppConfig()
        }
    }

    var session: PEPSession {
        return appConfig.session
    }

    func didSetAppConfig() {
        // do nothing. Meant to be overridden by subclasses that require this information
    }
}

extension TableViewControllerBase: KickOffMySelfProtocol {
    func startMySelf() {
        Log.shared.errorAndCrash(component: #function, errorString: "No appConfig?")
    }
}

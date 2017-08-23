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
    var appConfig: AppConfig? {
        get {
            guard _appConfig != nil else {
                Log.shared.errorAndCrash(component: #function, errorString: "No appConfig?")
                return nil
            }
            return _appConfig
        }
        set {
            _appConfig = newValue
            didSetAppConfig()
        }
    }

    var session: PEPSession {
        guard let config = appConfig else {
            Log.shared.errorAndCrash(component: #function, errorString: "No appConfig?")
            return PEPSession()
        }
        return config.session
    }

    func didSetAppConfig() {
        // do nothing. Ment to be overridden by subclasses that require this information
    }
}

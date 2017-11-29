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
                                    sleepTimeInSeconds: 2, backgrounder: nil, mySelfer: nil),
                                 errorHandler: ErrorPropagator())
            }
            return theAC
        }
        set {
            _appConfig = newValue
            didSetAppConfig()
        }
    }

    func didSetAppConfig() {
        appConfig.errorHandler.subscribe(self)
    }

    // The soley reason for implementing this method is to make sure
    // we did not forget to pass appConfig
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard _appConfig != nil else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "AppConfig is nil in viewWillAppear")
            return
        }
    }
}

extension BaseTableViewController: KickOffMySelfProtocol {
    func startMySelf() {
        Log.shared.errorAndCrash(component: #function, errorString: "No appConfig?")
    }
}

extension BaseTableViewController: ErrorPropagatorSubscriber {
    func errorPropagator(_ propagator: ErrorPropagator, errorHasBeenReported error: Error) {
        showError(error: error)
    }
}

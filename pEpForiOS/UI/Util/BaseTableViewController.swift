//
//  BaseTableViewController.swift
//  pEpForiOS
//
//  Created by buff on 23.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

class BaseTableViewController: UITableViewController, ErrorPropagatorSubscriber {
    private var _appConfig: AppConfig?

    var originalTitleView: String?

    var appConfig: AppConfig {
        get {
            guard let safeConfig = _appConfig else {
                Log.shared.errorAndCrash(component: #function, errorString: "No appConfig?")

                // We have no config. Return nonsense.
                return AppConfig(mySelfer: self,
                                 messageSyncService: MessageSyncService( sleepTimeInSeconds: 2,
                                                                         backgrounder: nil,
                                                                         mySelfer: nil),
                                 errorPropagator: ErrorPropagator())
            }
            return safeConfig
        }
        set {
            _appConfig = newValue
            didSetAppConfig()
        }
    }

    func didSetAppConfig() {
        // Do nothing. Meant to override in subclasses.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard _appConfig != nil else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "AppConfig is nil in viewWillAppear!")
            return
        }
        appConfig.errorPropagator.subscriber = self
    }

    // MARK: - ErrorPropagatorSubscriber

    func errorPropagator(_ propagator: ErrorPropagator, errorHasBeenReported error: Error) {
        UIUtils.show(error: error, inViewController: self)
    }
}

extension BaseTableViewController: KickOffMySelfProtocol {
    func startMySelf() {
        Log.shared.errorAndCrash(component: #function, errorString: "No appConfig?")
    }
}

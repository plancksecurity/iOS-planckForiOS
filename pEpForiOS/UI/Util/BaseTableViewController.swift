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

    var appConfig: AppConfig {
        get {
            guard let safeConfig = _appConfig else {
                Log.shared.errorAndCrash(component: #function, errorString: "No appConfig?")
                // We have no config. Return nonsense.
                return AppConfig(
                    mySelfer: self,
                    messageSyncService: MessageSyncService(),
                    errorPropagator: ErrorPropagator(),
                    keyImportService: KeyImportService(),
                    oauth2AuthorizationFactory: OAuth2ProviderFactory().oauth2Provider())
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
            if !MiscUtil.isUnitTest() {
                Log.shared.errorAndCrash(component: #function,
                                         errorString: "AppConfig is nil in viewWillAppear!")
            }
            return
        }
        appConfig.errorPropagator.subscriber = self
        self.navigationController?.title = title
    }

    // MARK: - ErrorPropagatorSubscriber

    var shouldHandleErrors: Bool = true

    func error(propagator: ErrorPropagator, error: Error) {
        if shouldHandleErrors {
            UIUtils.show(error: error, inViewController: self)
        }
    }
}

extension BaseTableViewController: KickOffMySelfProtocol {
    func startMySelf() {
        Log.shared.errorAndCrash(component: #function, errorString: "No appConfig?")
    }
}

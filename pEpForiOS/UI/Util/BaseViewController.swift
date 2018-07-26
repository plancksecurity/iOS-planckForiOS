//
//  BaseViewController.swift
//  pEpForiOS
//
//  Created by Andreas Buff on 23.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController, ErrorPropagatorSubscriber {
    private var _appConfig: AppConfig?
    var appConfig: AppConfig! {
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

    func didSetAppConfig() {
        // Do nothing. Meant to override in subclasses.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        appConfig?.errorPropagator.subscriber = self
    }

    // MARK: - ErrorPropagatorSubscriber

    var shouldHandleErrors: Bool = true

    func error(propagator: ErrorPropagator, error: Error) {
        if shouldHandleErrors {
            UIUtils.show(error: error, inViewController: self)
        }
    }
}

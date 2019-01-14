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
                Logger.frontendLogger.errorAndCrash("No appConfig?")
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
            if error is SmtpSendError || error is ImapSyncError {
                smtpOrImapAuthError(error: error)
            } else {
                UIUtils.show(error: error, inViewController: self)
            }
        }
    }

    func smtpOrImapAuthError(error: Error) {
        var extraInfo = ""

        if let smtpError = error as? SmtpSendError {
            switch smtpError {
            case .authenticationFailed( _, let account):
                extraInfo = account
            case .illegalState(_):
                break
            case .connectionLost(_):
                break
            case .connectionTerminated(_):
                break
            case .connectionTimedOut(_):
                break
            case .badResponse(_):
                break
            }
        } else if let imapError = error as? ImapSyncError {
            switch imapError {
            case .authenticationFailed(_, let account):
                extraInfo = account
            case .illegalState(_):
                break
            case .connectionLost(_):
                break
            case .connectionTerminated(_):
                break
            case .connectionTimedOut(_):
                break
            case .folderAppendFailed:
                break
            case .badResponse(_):
                break
            case .actionFailed:
                break
            }
        }
        let showed = appConfig.showedAccountsError[extraInfo]
        if let swd = showed, swd  {
            //this error must not be shown
        } else {
            UIUtils.show(error: error, inViewController: self)
            if showed == nil {
                appConfig.showedAccountsError[extraInfo] = false
            } else if showed == false {
                appConfig.showedAccountsError[extraInfo] = true
            }
        }
    }
}

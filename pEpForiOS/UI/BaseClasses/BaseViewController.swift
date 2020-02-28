//
//  BaseViewController.swift
//  pEpForiOS
//
//  Created by Andreas Buff on 23.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

import pEpIOSToolbox
import MessageModel

class BaseViewController: UIViewController, ErrorPropagatorSubscriber {
    private var _appConfig: AppConfig?
    var appConfig: AppConfig! {
        get {
            guard _appConfig != nil else {
                Log.shared.errorAndCrash("No appConfig?")
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
        appConfig?.keySyncHandshakeService.presenter = self
    }

    // MARK: - ErrorPropagatorSubscriber

    var shouldHandleErrors: Bool = true

    func error(propagator: ErrorPropagator, error: Error) {
        if shouldHandleErrors {
            if error is SmtpSendError || error is ImapSyncOperationError {
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
            case .sslPeerCertUnknown:
                break
            }
        } else if let imapError = error as? ImapSyncOperationError {
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
            case .sslPeerCertUnknown:
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

// MARK: - Stuff copy & pasted from BaseTableViewController.

extension BaseViewController {

    /// If applicable, shows the "empty selection" view controller in the details view.
    /// - Parameter message: The message to show in the view.
    func showEmptyDetailViewIfApplicable(message: String) {
        guard let spvc = splitViewController else {
            return
        }

        /// Inner function for doing the actual work.
        func showEmptyDetail() {
            let detailIndex = 1 // The index of the detail view controller

            if let emptyVC = spvc.viewControllers[safe: detailIndex] as? NothingSelectedViewController {
                emptyVC.message = message
                emptyVC.updateView()
            } else {
                let storyboard: UIStoryboard = UIStoryboard(
                    name: UIStoryboard.noSelectionStoryBoard,
                    bundle: nil)
                guard let detailVC = storyboard.instantiateViewController(
                    withIdentifier: UIStoryboard.nothingSelectedViewController) as? NothingSelectedViewController else {
                        return
                }
                detailVC.message = message
                spvc.showDetailViewController(detailVC, sender: self)
            }
        }

        switch spvc.currentDisplayMode {
        case .masterAndDetail:
            showEmptyDetail()
        case .onlyDetail:
            // nothing to do
            break
        case .onlyMaster:
            // nothing to do
            break
        }
    }
}

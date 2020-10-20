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

    /// Indicates when the navigation bar tint color must be white.
    /// As in iOS 13 the property to set that color changed, we use this flag to set it properly.
    /// Use it if for an specific view, the navigation bar tint color must be white.
    /// To use is, set it to true before the segue is performed.
    public var navigationBarTintColorWhite : Bool = false {
        didSet {
            if navigationBarTintColorWhite {
                guard let navController = navigationController else {
                    // This is a valid case. Not all ViewControllers are in a NavigationController
                    return
                }
                navController.navigationBar.barTintColor = .white
                navController.navigationBar.tintColor = .white
                UINavigationBar.appearance().tintColor = .white
            } else {
                //Keep the values of navigation navigationBar's tintColor and barTintColor to support the first loading.
                UINavigationBar.appearance().tintColor = .pEpGreen
            }
        }
    }

    var appConfig: AppConfig! {
        get {
            guard _appConfig != nil else {
                Log.shared.warn("No appConfig?")
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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationBarTintColorWhite = false
    }

    // MARK: - ErrorPropagatorSubscriber

    var shouldHandleErrors: Bool = true

    func error(propagator: ErrorPropagator, error: Error) {
        if shouldHandleErrors {
            if error is SmtpSendError || error is ImapSyncOperationError {
                smtpOrImapAuthError(error: error)
            } else {
                UIUtils.show(error: error)
            }
        }
    }

    func smtpOrImapAuthError(error: Error) {
        var extraInfo = ""

        if let smtpError = error as? SmtpSendError {
            switch smtpError {
            case .authenticationFailed( _, let account):
                extraInfo = account
            case .illegalState:
                break
            case .connectionLost:
                break
            case .connectionTerminated:
                break
            case .connectionTimedOut:
                break
            case .badResponse:
                break
            case .clientCertificateNotAccepted:
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
            case .clientCertificateNotAccepted:
                break
            }
        }
        let showed = appConfig.showedAccountsError[extraInfo]
        if let swd = showed, swd  {
            //this error must not be shown
        } else {
            UIUtils.show(error: error)
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

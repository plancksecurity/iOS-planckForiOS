//
//  BaseTableViewController.swift
//  pEpForiOS
//
//  Created by buff on 23.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

import pEpIOSToolbox
import MessageModel

class BaseTableViewController: UITableViewController, ErrorPropagatorSubscriber {

    private var _appConfig: AppConfig?
    var appConfig: AppConfig {
        get {
            guard let safeConfig = _appConfig else {
                Log.shared.errorAndCrash("No appConfig?")

                // We have no config. Return something.
                let errorPropagator = ErrorPropagator()
                let keySyncHandshakeService = KeySyncHandshakeService()
                let theMessageModelService = MessageModelService(errorPropagator: errorPropagator,
                                                                 cnContactsAccessPermissionProvider: AppSettings.shared,
                                                                 keySyncServiceDelegate: keySyncHandshakeService,
                                                                 keySyncEnabled: AppSettings.shared.keySyncEnabled)
                return AppConfig(errorPropagator: errorPropagator,
                                 oauth2AuthorizationFactory: OAuth2ProviderFactory().oauth2Provider(),
                                 keySyncHandshakeService: KeySyncHandshakeService(),
                                 messageModelService: theMessageModelService)
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
                Log.shared.errorAndCrash("AppConfig is nil in viewWillAppear!")
            }
            return
        }
        appConfig.errorPropagator.subscriber = self
        appConfig.keySyncHandshakeService.presenter = self
        self.navigationController?.title = title
        BaseTableViewController.setupCommonSettings(tableView: tableView)
    }

    static func setupCommonSettings(tableView: UITableView) {
        hideSeperatorForEmptyCells(on: tableView)
    }
    static private func hideSeperatorForEmptyCells(on tableView: UITableView) {
        // Add empty footer to not show empty cells (visible as dangling seperators)
        if tableView.tableFooterView == nil {
            tableView.tableFooterView = UIView(frame: .zero)
        }
    }

    func popToEmptyDetail(message: String) {
        guard let spvc = splitViewController else {
            return
        }
        switch spvc.currentDisplayMode {
        case .masterAndDetail:
            guard let navDetail = spvc.viewControllers[safe: 2] as? UINavigationController else {
                return
            }
            guard let detailVC = navDetail.rootViewController as? NoMessagesViewController else {
                return
            }
            detailVC.message = message
            navDetail.popToViewController(detailVC, animated: true)
            break
        case .onlyDetail:
            // nothing to do
            break
        case .onlyMaster:
            // nothing to do
            break
        }
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

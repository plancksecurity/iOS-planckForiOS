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
    var keyimportWizard: KeyImportWizzard?

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
        BaseTableViewController.setupCommonSettings(tableView: tableView)

        if keyimportWizard == nil {
            keyimportWizard = KeyImportWizzard(keyImportService: appConfig.keyImportService, starter: false)
            keyimportWizard?.startKeyImportDelegate = self //IOS-1028: we want to do this everytime as far as I can see.
        }
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

import MessageModel
//TODO: Move to proper site
extension BaseTableViewController: StartKeyImportDelegate {

    func startKeyImport(account: Account) {
        let storyId = AutoWizardStepsViewController.storyBoardID
        if let vc = UIStoryboard.init(name: "KeyImport", bundle: Bundle.main)
            .instantiateViewController(withIdentifier: storyId) as? AutoWizardStepsViewController {
            vc.appConfig = self.appConfig
            if let wizard = keyimportWizard {
                vc.viewModel = AutoWizardStepsViewModel(keyImportService: appConfig.keyImportService,
                    account: account, keyImportWizzard: wizard)
            }

            self.present(vc, animated: true)
        }

    }
}

//
//  AccountSettingsViewController.swift
//  pEp
//
//  Created by Martin Brude on 27/05/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit
import Foundation
import MessageModel
import pEpIOSToolbox

final class AccountSettingsViewController : BaseViewController {
    @IBOutlet private var tableView: UITableView!

    // MARK: - Variables
    private let oauthViewModel = OAuthAuthorizer()

    var viewModel: AccountSettingsViewModel2? = nil

    override var collapsedBehavior: CollapsedSplitViewBehavior {
        return .needed
    }

    override var separatedBehavior: SeparatedSplitViewBehavior {
        return .detail
    }

    // MARK: - Life Cycle

     override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(pEpHeaderView.self, forHeaderFooterViewReuseIdentifier: pEpHeaderView.reuseIdentifier)
        UIHelper.variableContentHeight(tableView)
        viewModel?.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        configureView(for: traitCollection)
        oauthViewModel.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showNavigationBar()
        title = NSLocalizedString("Account", comment: "Account view title")
        navigationController?.navigationController?.setToolbarHidden(true, animated: false)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let sections = viewModel?.sections else {
            Log.shared.errorAndCrash("Without sections there is no table view.")
            return
        }

        let row = sections[indexPath.section].rows[indexPath.row]
        if row.type == .reset {
            handleResetIdentity()
        }
    }
}

extension AccountSettingsViewController : AccountSettingsViewModelDelegate {
    func showErrorAlert(error: Error) {

    }

    func undoPEPSyncToggle() {

    }

    func showLoadingView() {

    }

    func hideLoadingView() {

    }
}

//MARK : - Certificate

extension AccountSettingsViewController {

    /// TODO: call this.
    /// Present Client Certificate view
    private func handleCertificate() {
        guard let vc = UIStoryboard.init(name: "AccountCreation", bundle: nil).instantiateViewController(withIdentifier: "ClientCertificateManagementViewController") as? ClientCertificateManagementViewController,
            let vm = viewModel else {
            Log.shared.errorAndCrash("AccountSettingsViewModel or ClientCertificateManagementViewController not found")
            return
        }
        vc.appConfig = appConfig
        let nextViewModel = vm.clientCertificateViewModel()
        nextViewModel.delegate = vc
        vc.viewModel = nextViewModel
        navigationController?.pushViewController(vc, animated: true)
    }

    private func handleOauth2Reauth() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash(message: "A view model is required")
            return
        }

        guard let accountType = vm.account.accountType else {
            Log.shared.errorAndCrash(message: "Handling OAuth2 reauth requires an account with a known account type for determining the OAuth2 configuration")
            return
        }

//        oauth2ActivityIndicator.startAnimating()

        // don't accept errors form other places
        shouldHandleErrors = false

        oauthViewModel.authorize(
            authorizer: appConfig.oauth2AuthorizationFactory.createOAuth2Authorizer(),
            emailAddress: vm.account.user.address,
            accountType: accountType,
            viewController: self)
    }

    /// Shows an alert to warn the user about resetting the identities
    private func handleResetIdentity() {
        let title = NSLocalizedString("Reset", comment: "Account settings confirm to reset identity title alert")
        let message = NSLocalizedString("This action will reset your identity. \n Are you sure you want to reset?", comment: "Account settings confirm to reset identity title alert")

        guard let pepAlertViewController =
            PEPAlertViewController.fromStoryboard(title: title,
                                                  message: message,
                                                  paintPEPInTitle: true) else {
                                                    Log.shared.errorAndCrash("Fail to init PEPAlertViewController")
                                                    return
        }

        let cancelTitle = NSLocalizedString("Cancel",
                                            comment: "Cancel reset account identity button title")
        let cancelAction = PEPUIAlertAction(title: cancelTitle,
                                            style: .pEpGray,
                                            handler: { _ in
                                                pepAlertViewController.dismiss(animated: true,
                                                                               completion: nil)
        })
        pepAlertViewController.add(action: cancelAction)

        let resetTitle = NSLocalizedString("Reset",
                                           comment: "Reset account identity button title")
        let resetAction = PEPUIAlertAction(title: resetTitle,
                                           style: .pEpRed,
                                           handler: { [weak self] _ in
                                            pepAlertViewController.dismiss(animated: true,
                                                                           completion: nil)
                                            guard let me = self else {
                                                Log.shared.lostMySelf()
                                                return
                                            }
                                            me.viewModel?.handleResetIdentity()
        })
        pepAlertViewController.add(action: resetAction)
        pepAlertViewController.modalPresentationStyle = .overFullScreen
        pepAlertViewController.modalTransitionStyle = .crossDissolve
        DispatchQueue.main.async { [weak self] in
            self?.present(pepAlertViewController, animated: true)
        }
    }
}


//MARK : - Accessibility

extension AccountSettingsViewController {

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
      super.traitCollectionDidChange(previousTraitCollection)
      if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
        configureView(for: traitCollection)
      }
    }

    /// Setup the layout according to the current trait collection.
    /// - Parameter traitCollection: The current trait collection.
    private func configureView(for traitCollection: UITraitCollection) {
        let contentSize = traitCollection.preferredContentSizeCategory
        let axis : NSLayoutConstraint.Axis = contentSize.isAccessibilityCategory ? .vertical : .horizontal
        let spacing : CGFloat = contentSize.isAccessibilityCategory ? 10.0 : 5.0
        print(axis)
        print(spacing)
    }
}

extension AccountSettingsViewController : UITableViewDelegate {

}

extension AccountSettingsViewController : UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        guard let numberOfSections = viewModel?.sections.count else {
            Log.shared.errorAndCrash("Without sections there is no table view.")
            return 0
        }
        return numberOfSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = viewModel?.sections else {
            Log.shared.errorAndCrash("Without sections there is no table view.")
            return 0
        }
        return sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sections = viewModel?.sections else {
            Log.shared.errorAndCrash("Without sections there is no table view.")
            return UITableViewCell()
        }

        let row = sections[indexPath.section].rows[indexPath.row]
        switch row.type {
        case .name, .email, .password,
             .server, .port, .tranportSecurity, .username:
            if let dequeuedCell = tableView.dequeueReusableCell(withIdentifier: row.cellIdentifier)
                as? AccountSettingsKeyValueTableViewCell {
                guard let row = row as? AccountSettingsViewModel2.DisplayRow else {
                    Log.shared.errorAndCrash(message: "Row doesn't match the expected type")
                    return UITableViewCell()
                }
                dequeuedCell.configure(with: row)
                return dequeuedCell
            }
        case .pepSync:
            if let dequeuedCell = tableView.dequeueReusableCell(withIdentifier: row.cellIdentifier)
                as? AccountSettingsSwitchTableViewCell {
                guard let row = row as? AccountSettingsViewModel2.SwitchRow else {
                    Log.shared.errorAndCrash(message: "Row doesn't match the expected type")
                    return UITableViewCell()
                }
                dequeuedCell.configure(with: row)
                return dequeuedCell
            }
        case .reset:
            if let dequeuedCell = tableView.dequeueReusableCell(withIdentifier: row.cellIdentifier)
                as? AccountSettingsDangerousTableViewCell {
                guard let row = row as? AccountSettingsViewModel2.ActionRow else {
                    Log.shared.errorAndCrash(message: "Row doesn't match the expected type")
                    return UITableViewCell()
                }
                //Appearance.configureSelectedBackgroundViewForPep(tableViewCell: dequeuedCell)
                dequeuedCell.configure(with: row)
                return dequeuedCell
            }
        }
        Log.shared.errorAndCrash(message: "We should never return an empty UITableViewCell.")
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: pEpHeaderView.reuseIdentifier) as? pEpHeaderView else {
            Log.shared.errorAndCrash("pEpHeaderView doesn't exist!")
            return nil
        }
        guard let sections = viewModel?.sections else {
            Log.shared.errorAndCrash("Without sections there is no table view.")
            return nil
        }

        headerView.title = sections[section].title.uppercased()
        return headerView
    }

    private enum CellType {
        case keyValueCell
        case switchCell
        case dangerousCell
    }

}

// MARK: - OAuthAuthorizerDelegate

extension AccountSettingsViewController: OAuthAuthorizerDelegate {
    func didAuthorize(oauth2Error: Error?, accessToken: OAuth2AccessTokenProtocol?) {
        //oauth2ActivityIndicator.stopAnimating()
        shouldHandleErrors = true

        if let error = oauth2Error {
            showErrorAlert(error: error)
            return
        }
        guard let token = accessToken else {
            showErrorAlert(error: OAuthAuthorizerError.noToken)
            return
        }
        viewModel?.updateToken(accessToken: token)
    }
}

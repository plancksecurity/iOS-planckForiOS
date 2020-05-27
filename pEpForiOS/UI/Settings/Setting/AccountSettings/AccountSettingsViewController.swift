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
//        tableView.register(AccountSettingsKeyValueTableViewCell.self, forCellReuseIdentifier: AccountSettingsKeyValueTableViewCell.identifier)
        UIHelper.variableCellHeightsTableView(tableView)
        UIHelper.variableSectionFootersHeightTableView(tableView)
        UIHelper.variableSectionHeadersHeightTableView(tableView)
        viewModel?.delegate = self
        tableView.delegate = self
        tableView.dataSource = self

        configureView(for: traitCollection)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showNavigationBar()
        title = NSLocalizedString("Account", comment: "Account view title")
        navigationController?.navigationController?.setToolbarHidden(true, animated: false)
        //Work around async old stack context merge behaviour
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.setupView()
        }
    }

    private func setupView() {
        title = NSLocalizedString("Account", comment: "Account settings")
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
        let dequeuedCell = UITableViewCell()

//        Appearance.configureSelectedBackgroundViewForPep(tableViewCell: dequeuedCell)

        switch row.type {
        case .name, .email, .password, .server, .port, .tranportSecurity, .username:
            if let dequeuedCell = tableView.dequeueReusableCell(withIdentifier: row.cellIdentifier) as? AccountSettingsKeyValueTableViewCell {
                guard let row = row as? AccountSettingsViewModel2.DisplayRow else {
                    Log.shared.errorAndCrash(message: "Row doesn't match the expected type")
                    return UITableViewCell()
                }
                dequeuedCell.keyLabel.text = row.title
                dequeuedCell.valueTextfield.text = row.text
                dequeuedCell.configure()
                return dequeuedCell
            }
        case .pepSync:
            return dequeuedCell
//            dequeuedCell = tableView.dequeueReusableCell(withIdentifier: row.cellIdentifier, for: indexPath)
        case .reset:
//            dequeuedCell = tableView.dequeueReusableCell(withIdentifier: row.cellIdentifier, for: indexPath)
            return dequeuedCell
        }

        return dequeuedCell
    }

    private enum CellType {
        case keyValueCell
        case switchCell
        case dangerousCell
    }
}

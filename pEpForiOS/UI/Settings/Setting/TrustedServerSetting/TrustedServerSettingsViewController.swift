//
//  TrustedServerSettingsViewController.swift
//  pEp
//
//  Created by Martin Brude on 02/04/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

import pEpIOSToolbox

class TrustedServerSettingsViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    private var viewModel = TrustedServerSettingsViewModel()
    
    override var collapsedBehavior: CollapsedSplitViewBehavior {
        return .needed
    }

    override var separatedBehavior: SeparatedSplitViewBehavior {
        return .detail
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(PEPHeaderView.self, forHeaderFooterViewReuseIdentifier: PEPHeaderView.reuseIdentifier)
        tableView.register(pEpFooterView.self, forHeaderFooterViewReuseIdentifier: pEpFooterView.reuseIdentifier)
        tableView.contentInsetAdjustmentBehavior = .always
        UIHelper.variableCellHeightsTableView(tableView)
        UIHelper.variableSectionFootersHeightTableView(tableView)
        UIHelper.variableSectionHeadersHeightTableView(tableView)

        tableView.dataSource = self
        tableView.delegate = self

        title = NSLocalizedString("Store Messages Securely", comment: "Store Messages Securely Title")
        viewModel.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showNavigationBar()
    }
}

// MARK: -  UITableViewDataSource

extension TrustedServerSettingsViewController : UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell =
            tableView.dequeueReusableCell(withIdentifier: TrustedServerSettingCell.storyboardId) as?
            TrustedServerSettingCell
            else {
                return UITableViewCell()
        }
        cell.delegate = self
        let row = viewModel.rows[indexPath.row]
        cell.address.text = row.address
        cell.onOfSwitch.setOn(row.storeMessagesSecurely, animated: false)
        configure(cell: cell, for: traitCollection)
        return cell
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        tableView.reloadData()
    }

    private func configure(cell : TrustedServerSettingCell, for traitCollection: UITraitCollection) {
        let contentSize = traitCollection.preferredContentSizeCategory
        let axis : NSLayoutConstraint.Axis = contentSize.isAccessibilityCategory ? .vertical : .horizontal
        let spacing : CGFloat = contentSize.isAccessibilityCategory ? 10.0 : 5.0
        cell.stackView.axis = axis
        cell.stackView.spacing = spacing
    }
}

// MARK: - UITableViewDelegate

extension TrustedServerSettingsViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: PEPHeaderView.reuseIdentifier) as? PEPHeaderView else {
            Log.shared.errorAndCrash("pEpHeaderView doesn't exist!")
            return nil
        }
        headerView.title = NSLocalizedString("Store Messages Securely", comment: "Trusted Server Setting Section Title")
        return headerView
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: pEpFooterView.reuseIdentifier) as? pEpFooterView else {
            Log.shared.errorAndCrash("pEpHeaderView doesn't exist!")
            return nil
        }
        let text = NSLocalizedString("If disabled, an unencrypted copy of each message is stored on the server.\n\nDo not disable if you are not sure what you are doing!", comment: "Trusted Server Setting Section Footer")

        headerView.title = text
        
        return headerView
    }
}

// MARK: - TrustedServerSettingCellDelegate

extension TrustedServerSettingsViewController: TrustedServerSettingCellDelegate {
    func trustedServerSettingCell(sender: TrustedServerSettingCell, didChangeSwitchValue newValue: Bool) {
        guard let indexPath = tableView.indexPath(for: sender) else {
            Log.shared.errorAndCrash("Invalid indexPath for this TrustedServerSettingCell")
            return
        }
        viewModel.handleStoreSecurely(indexPath: indexPath, toValue: newValue)
    }
}

// MARK: - TrustedServerSettingsViewModelDelegate

extension TrustedServerSettingsViewController: TrustedServerSettingsViewModelDelegate {
    public func showAlertBeforeStoringSecurely(forIndexPath indexPath: IndexPath) {
        let title = NSLocalizedString("Security Alert", comment: "Alert title before trusting an account")
        let message = NSLocalizedString("This is a public cloud account. Your data will be exposed. Are you sure you want to configure this as trusted?", comment: "Alert message before trusting an account")
        let cancelActionTitle = NSLocalizedString("Cancel", comment: "Alert cancel button title before trusting an account")
        let trustActionTitle = NSLocalizedString("Trust", comment: "Alert trust button title before trusting an account")
        let cancelAction = { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            guard let trustCell = me.tableView.cellForRow(at: indexPath) as? TrustedServerSettingCell else {
                Log.shared.errorAndCrash("Fail to get TrustedServerSettingCell")
                return
            }
            trustCell.onOfSwitch.setOn(false, animated: true)
        }
        let positiveAction = { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.viewModel.setStoreSecurely(indexPath: indexPath, toValue: false)
        }
        UIUtils.showTwoButtonAlert(withTitle: title, message: message,
                                   cancelButtonText: cancelActionTitle,
                                   positiveButtonText: trustActionTitle,
                                   cancelButtonAction: cancelAction,
                                   positiveButtonAction: positiveAction,
                                   style: .warn)
    }
}

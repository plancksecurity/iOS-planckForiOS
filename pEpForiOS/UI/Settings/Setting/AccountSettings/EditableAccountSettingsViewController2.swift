//
//  EditableAccountSettingsViewController2.swift
//  pEp
//
//  Created by Martín Brude on 04/12/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit
import pEpIOSToolbox

class EditableAccountSettingsViewController2: UIViewController {

    override var collapsedBehavior: CollapsedSplitViewBehavior {
        return .needed
    }

    override var separatedBehavior: SeparatedSplitViewBehavior {
        return .detail
    }

    var viewModel : EditableAccountSettingsViewModel2?
    @IBOutlet private var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(PEPHeaderView.self, forHeaderFooterViewReuseIdentifier: PEPHeaderView.reuseIdentifier)
        tableView.hideSeperatorForEmptyCells()
        UIHelper.variableContentHeight(tableView)

    }

    @IBAction func saveButtonTapped(_ sender: UIBarButtonItem) {
        print("Save button tapped")
    }

    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        dismissYourself()
    }
}

// MARK: - UITableViewDataSource

extension EditableAccountSettingsViewController2: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return 0
        }

        return vm.sections[section].rows.count
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return 0
        }
        return vm.sections.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return UITableViewCell()
        }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AccountSettingsTableViewCell.identifier) as? AccountSettingsTableViewCell else {
            return UITableViewCell()
        }
        guard let row = vm.sections[indexPath.section].rows[indexPath.row] as? AccountSettingsViewModel.DisplayRow else {
            Log.shared.errorAndCrash("Can't dequeue row")
            return cell
        }
        cell.configure(with: row, for: traitCollection)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension EditableAccountSettingsViewController2: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: PEPHeaderView.reuseIdentifier) as? PEPHeaderView else {
            Log.shared.errorAndCrash("pEpHeaderView doesn't exist!")
            return nil
        }
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return nil
        }
        headerView.title = vm.sections[section].title.uppercased()
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
}

// MARK: - EditableAccountSettingsDelegate2

extension EditableAccountSettingsViewController2: EditableAccountSettingsDelegate2 {
    func setLoadingView(visible: Bool) {
        if visible {
            LoadingInterface.showLoadingInterface()
        } else {
            LoadingInterface.removeLoadingInterface()
        }
    }

    func showAlert(error: Error) {
        UIUtils.show(error: error)
    }

    func dismissYourself() {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Accessibility

extension EditableAccountSettingsViewController2 {

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            tableView.reloadData()
        }
    }
}

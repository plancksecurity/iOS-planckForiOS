//
//  AuditLoggingViewController.swift
//  planckForiOS
//
//  Created by Martin Brude on 6/6/23.
//  Copyright © 2023 p≡p Security S.A. All rights reserved.
//

import UIKit
import PlanckToolbox

class AuditLoggingViewController: UIViewController {


    @IBOutlet private weak var tableView: UITableView!
    static private let maxTimeCellId = "AuditLoggingMaxTimeCellId"

    public var viewModel: AuditLoggingViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.register(PEPHeaderView.self, forHeaderFooterViewReuseIdentifier: PEPHeaderView.reuseIdentifier)
        tableView.backgroundColor = .clear
        view.backgroundColor = UIColor.systemGroupedBackground
        UIHelper.variableContentHeight(tableView)
        title = NSLocalizedString("Audit Loggin", comment: "Audit Loggin Title")
        let saveButton = UIBarButtonItem(title: NSLocalizedString("Save", comment: "Save - Right bar button item in Audit Loggin view"),
                                         style: .plain,
                                         target: self,
                                         action: #selector(saveButtonPressed))
        saveButton.accessibilityIdentifier = AccessibilityIdentifier.saveButton
        navigationItem.rightBarButtonItem = saveButton
    }

    @objc func saveButtonPressed() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }
        AppSettings.shared.auditLoggingTime = vm.currentAuditLoggingTime
        navigationController?.popViewController(animated: true)
    }
}

extension AuditLoggingViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: PEPHeaderView.reuseIdentifier) as? PEPHeaderView else {
            Log.shared.errorAndCrash("pEpHeaderView doesn't exist!")
            return nil
        }

        headerView.title = NSLocalizedString("The audit log time frame can be adjusted, the default value is 30 days.", comment: "Header text")
        return headerView
    }
}

extension AuditLoggingViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return 0
        }
        return vm.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return 0
        }
        return vm.sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return UITableViewCell()
        }
        let row = vm.sections[indexPath.section].rows[indexPath.row]
        switch row.type {
        case .maxTime:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: AuditLoggingViewController.maxTimeCellId) as? AuditLoggingTableViewCell else {
                Log.shared.errorAndCrash("AuditLoggingViewController not found")
                return AuditLoggingTableViewCell()
            }
            cell.config(viewModel: vm)
            cell.delegate = self
            return cell
        }
    }
}

extension AuditLoggingViewController: AuditLoggingDelegate {
    func auditLoggingValueDidChange(newValue: Int) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }
        navigationItem.rightBarButtonItem?.isEnabled = vm.shouldEnableSaveButton(newValue: newValue)
    }
}

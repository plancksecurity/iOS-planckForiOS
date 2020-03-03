//
//  ClientCertificatesTableViewController.swift
//  pEp
//
//  Created by Adam Kowalski on 02/03/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

final class ClientCertificatesTableViewController: UITableViewController {

    var viewModel: ClientCertificateManagementViewModel? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
        setupViewModel()
    }
}

// MARK: - Private

extension ClientCertificatesTableViewController {
    private func setupTableView() {
        tableView.separatorInset = .zero
        tableView.separatorStyle = .none
    }

    private func setupViewModel() {
        if viewModel == nil {
            viewModel = ClientCertificateManagementViewModel()
        }
    }
}

// MARK: - UITableViewDataSource

extension ClientCertificatesTableViewController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return 0
        }
        return vm.rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ClientChooseCertificateCell.reusableId) as? ClientChooseCertificateCell else {
            Log.shared.errorAndCrash("No reusable cell")
            return UITableViewCell()
        }
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return UITableViewCell()
        }
        let row = vm.rows[indexPath.row]
        cell.titleLabel?.text = row.name
        return cell
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        // Hide seperator lines for empty view.
        return UIView()
    }
}

// MARK: - UITableViewDelegate

extension ClientCertificateManagementViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }
        vm.handleDidSelect(rowAt: indexPath)
        dismiss(animated: true)
    }
}

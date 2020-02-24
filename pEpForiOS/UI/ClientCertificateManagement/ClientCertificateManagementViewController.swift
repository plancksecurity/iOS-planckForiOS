//
//  ClientCertificateManagementViewController.swift
//  pEp
//
//  Created by Andreas Buff on 24.02.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

class ClientCertificateManagementViewController: BaseViewController {
    static let storiboardID = "ClientCertificateManagementViewController"
    static let cellID = "ClientCertificateManagementTableViewCell"
    @IBOutlet weak var tableView: UITableView!
    public var viewModel: ClientCertificateManagementViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setup()
    }
}

// MARK: - Private

extension ClientCertificateManagementViewController {

    private func setup() {
        tableView.delegate = self
        tableView.dataSource = self
    }

    private func setupViewModel() {
        guard viewModel == nil else {
            // Already setup.
            // Nothing to do.
            return
        }
        viewModel = ClientCertificateManagementViewModel()
    }
}

// MARK: - UITableViewDelegate

extension ClientCertificateManagementViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        fatalError("Unimplemented stub")
    }
}

// MARK: - UITableViewDataSource

extension ClientCertificateManagementViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return 0
        }
        return vm.rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =
            tableView.dequeueReusableCell(withIdentifier: ClientCertificateManagementViewController.cellID,
                                          for: indexPath)
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return UITableViewCell()
        }
        let row = vm.rows[indexPath.row]
        cell.textLabel?.text = row.name
        return cell
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        // Hide seperator lines for empty view.
        return UIView()
    }
}

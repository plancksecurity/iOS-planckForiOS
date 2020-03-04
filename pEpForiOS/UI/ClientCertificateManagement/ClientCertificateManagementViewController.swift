//
//  ClientCertificateManagementViewController.swift
//  pEp
//
//  Created by Andreas Buff on 24.02.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

/// View that lists all imported client certificates and let's the user choose one.
final class ClientCertificateManagementViewController: BaseViewController {

    @IBOutlet weak var tableView: UITableView!

    public var viewModel: ClientCertificateManagementViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        setupTableView()
        setupViewModel()
        configureAppearance()
    }
}

// MARK: - Private

extension ClientCertificateManagementViewController {
    private func setupViewModel() {
        guard viewModel == nil else {
            // Already setup.
            // Nothing to do.
            return
        }
        viewModel = ClientCertificateManagementViewModel()
    }

    private func configureAppearance() {
        if #available(iOS 13, *) {
            Appearance.customiseForLogin(viewController: self)
        } else {
            navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationController?.navigationBar.shadowImage = UIImage()
            navigationController?.navigationBar.isTranslucent = true
            navigationController?.navigationBar.backgroundColor = UIColor.clear
        }
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.tintColor = .white
    }

    private func setupTableView() {
        if viewModel == nil {
            viewModel = ClientCertificateManagementViewModel()
        }
        tableView.separatorInset = .zero
        tableView.separatorStyle = .none
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
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        // Hide seperator lines for empty view.
        return UIView()
    }
}

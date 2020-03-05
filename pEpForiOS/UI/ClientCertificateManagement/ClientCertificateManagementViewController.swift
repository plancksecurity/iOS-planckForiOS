//
//  ClientCertificateManagementViewController.swift
//  pEp
//
//  Created by Andreas Buff on 24.02.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

private struct Localized {
    static let importDate = NSLocalizedString("Import date",
                                              comment: "Select certificate - import certificate date")
    static let colon = NSLocalizedString(":",
                                         comment: "Select certificate - import certificate date colon")
    static let separator = " "
}

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
    private func formatDate(date: Date?) -> String? {
        guard let date = date else {
            Log.shared.errorAndCrash("date is optional!")
            return nil
        }
        let dateFormatter = DateFormatter.init()
        dateFormatter.dateStyle = DateFormatter.Style.short
        dateFormatter.timeStyle = DateFormatter.Style.short
        return dateFormatter.string(from: date)
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
        performSegue(withIdentifier: SegueIdentifier.showLogin, sender: self)
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ClientCertificateSelectionCell.reusableId) as? ClientCertificateSelectionCell else {
            Log.shared.errorAndCrash("No reusable cell")
            // We prefer empty cell than app crash
            return UITableViewCell()
        }
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            // We prefer empty cell than app crash
            return UITableViewCell()
        }
        let row = vm.rows[indexPath.row]
        let date = Localized.importDate
            + Localized.colon
            + Localized.separator
            + (formatDate(date: row.date) ?? "")
        cell.setData(title: row.name, date: date)
        return cell
    }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        // Hide seperator lines for empty view.
        return UIView()
    }
}

// MARK: - SegueHandlerType

extension ClientCertificateManagementViewController: SegueHandlerType {
    public enum SegueIdentifier: String {
        case showLogin
    }


    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }
        switch segueIdentifier(for: segue) {
        case .showLogin:
            guard let dvc = segue.destination as? LoginViewController else {
                    Log.shared.errorAndCrash("No DVC")
                    return
            }
            dvc.appConfig = appConfig
            let dvm = vm.loginViewModel()
            dvc.viewModel = dvm
        }
    }
}

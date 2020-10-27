//
//  KeyImportViewController.swift
//  pEp
//
//  Created by Dirk Zimmermann on 14.05.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

class KeyImportViewController: BaseViewController {
    static private let cellID = "KeyImportTableViewCell"

    public let viewModel = KeyImportViewModel()

    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super .viewDidLoad()

        viewModel.delegate = self

        tableView.delegate = self
        tableView.dataSource = self

        title = NSLocalizedString("Available Keys",
                                  comment: "Title of the view for choosing installed keys to import")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadRows()
    }
}

// MARK: - UITableViewDelegate

extension KeyImportViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.handleDidSelect(rowAt: indexPath)
    }
}

// MARK: - UITableViewDataSource

extension KeyImportViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        // Suppress seperator lines for empty cells
        return UIView(frame: CGRect.zero)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: KeyImportViewController.cellID)
            else {
                return UITableViewCell()
        }

        cell.textLabel?.text = viewModel.rows[indexPath.row].fileName

        return cell
    }
}

// MARK: - KeyImportViewModelDelegate

extension KeyImportViewController: KeyImportViewModelDelegate {
    static private let alertTitle = NSLocalizedString("PGP Key Import",
                                                      comment: "Title for alert when trying to import a key")

    func rowsLoaded() {
        tableView.reloadData()
    }

    func showConfirmSetOwnKey(keys: [KeyImportViewModel.KeyDetails]) {
        func userAccepted() {
            viewModel.setOwnKeys(keys: keys)
        }

        func userCanceled() {
            // nothing to do
        }

        let yesMessage = NSLocalizedString("OK",
                                           comment: "Title for yes button when trying to import a key")
        let noMessage = NSLocalizedString("Cancel",
                                          comment: "Title for no button (cancel) when trying to import a key")
        let message = String.localizedStringWithFormat(NSLocalizedString("The fingerprint of the selected key is:\n%1$@\n%2$@\n\nImport and use this key?",
                                                                         comment: "Message when asking user for confirmation about importing keys"),
                                                       viewModel.userPresentableFingerprint(keyDetails: keys),
                                                       viewModel.userPresentableNames(keyDetails: keys))

        UIUtils.showTwoButtonAlert(withTitle: KeyImportViewController.alertTitle,
                                   message: message,
                                   cancelButtonText: noMessage,
                                   positiveButtonText: yesMessage,
                                   cancelButtonAction: userCanceled,
                                   positiveButtonAction: userAccepted,
                                   style: .default)
    }

    func showError(message: String) {
        UIUtils.showAlertWithOnlyPositiveButton(title: KeyImportViewController.alertTitle,
                                                message: message)
    }

    func showSetOwnKeySuccess() {
        let message = NSLocalizedString("Private key successfully imported.",
                                        comment: "Success message when importing the key")
        UIUtils.showAlertWithOnlyPositiveButton(title: KeyImportViewController.alertTitle,
                                                message: message)
    }
}

//
//  EditableAccountSettingsViewController.swift
//  pEp
//
//  Created by Alejandro Gelos on 08/10/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit
import MessageModel

final class EditableAccountSettingsViewController: UIViewController {

    @IBOutlet private weak var saveButton: UIBarButtonItem!

    var viewModel: EditableAccountSettingsViewModel?
    override func viewDidLoad() {
        super.viewDidLoad()

        setUp()
        viewModel?.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationController?.setToolbarHidden(true, animated: false)
    }

    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        popViewController()
    }

    @IBAction func saveButtonTapped(_ sender: UIBarButtonItem) {
            view.endEditing(true)
            viewModel?.handleSaveButton()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let tableViewController as EditableAccountSettingsTableViewController:
            guard let account = viewModel?.account else {
                Log.shared.errorAndCrash("Founded nil account in EditableAccountSettingsViewController")
                return
            }
            tableViewController.viewModel =
                EditableAccountSettingsTableViewModel(account: account,
                                                      delegate: tableViewController)
            viewModel?.tableViewModel = tableViewController.viewModel
        default:
            break
        }
    }
}

// MARK: - Private

extension EditableAccountSettingsViewController {
    private struct Localized {
        static let navigationTitle = NSLocalizedString("Account",
                                                       comment: "Account settings")
    }
    private func setUp() {
        title = Localized.navigationTitle
    }
}

// MARK: - EditableAccountSettingsViewModelDelegate

extension EditableAccountSettingsViewController: EditableAccountSettingsViewModelDelegate {
    func showErrorAlert(error: Error) {
        UIUtils.show(error: error)
    }

    func showLoadingView() {
        DispatchQueue.main.async {
            LoadingInterface.showLoadingInterface()
        }
    }

    func hideLoadingView() {
        DispatchQueue.main.async {
            LoadingInterface.removeLoadingInterface()
        }
    }

    func popViewController() {
        navigationController?.popViewController(animated: true)
    }
}

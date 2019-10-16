//
//  EditableAccountSettingsViewController.swift
//  pEp
//
//  Created by Alejandro Gelos on 08/10/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit
import MessageModel

final class EditableAccountSettingsViewController: BaseViewController {

    @IBOutlet weak var saveButton: UIBarButtonItem!

    var viewModel: EditableAccountSettingsViewModel?

    override func viewDidLoad() {
        viewModel?.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationController?.setToolbarHidden(true, animated: false)

        guard splitViewController?.isCollapsed == false else { return }
        self.navigationItem.leftBarButtonItem = nil// hidesBackButton = true
    }

    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        guard splitViewController?.isCollapsed == true else { return }
        popViewController()
    }

    @IBAction func saveButtonTapped(_ sender: UIBarButtonItem) {
        viewModel?.handleSaveButton()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let tableViewController as EditableAccountSettingsTableViewController:
            tableViewController.viewModel = EditableAccountSettingsTableViewModel()
            viewModel?.tableViewModel = tableViewController.viewModel
        default:
            break
        }
    }
}


// MARK: - EditableAccountSettingsViewModelDelegate

extension EditableAccountSettingsViewController: EditableAccountSettingsViewModelDelegate {
    func showErrorAlert(error: Error) {
        Log.shared.error("%@", "\(error)")
        UIUtils.show(error: error, inViewController: self)
    }

//    func showErrorAlert(title: String, message: String, buttonTitle: String) {
//        guard let errorAlert =
//            PEPAlertViewController.fromStoryboard(title: title, message: message) else {
//                return
//        }
//
//        let okAction = PEPUIAlertAction(title: buttonTitle,
//                                        style: .pEpBlue,
//                                        handler: { [weak errorAlert] alert in
//                                            errorAlert?.dismiss(animated: true)
//        })
//
//        errorAlert.add(action: okAction)
//        DispatchQueue.main.async { [weak self] in
//            self?.present(errorAlert, animated: true)
//        }
//    }

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
        //!!!: see IOS-1608 this is a patch as we have 2 navigationControllers and need to pop to the previous view.
        (navigationController?.parent as? UINavigationController)?.popViewController(animated: true)
    }
}

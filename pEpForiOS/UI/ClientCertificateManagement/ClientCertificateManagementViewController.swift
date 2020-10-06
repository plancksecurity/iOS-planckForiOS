//
//  ClientCertificateManagementViewController.swift
//  pEp
//
//  Created by Andreas Buff on 24.02.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

import SwipeCellKit

import pEpIOSToolbox

private struct Localized {
    static let importDate = NSLocalizedString("Import date",
                                              comment: "Select certificate - import certificate date")
}

/// View that lists all imported client certificates and let's the user choose one.
final class ClientCertificateManagementViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var addCertButton: UIButton!
    @IBOutlet private weak var selectCertificateTitleLabel: UILabel!
    @IBOutlet private weak var selectCertificateSubtitleLabel: UILabel!

    public var viewModel: ClientCertificateManagementViewModel?
    
    //swipe acctions types
    var buttonDisplayMode: ButtonDisplayMode = .titleAndImage
    var buttonStyle: ButtonStyle = .backgroundColor
    
    private var swipeDelete: SwipeAction? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        setupTableView()
        configureAppearance()
    }

    @IBAction func addCertificateButtonPressed(_ sender: Any) {
        let picker = UIDocumentPickerViewController(documentTypes: ["public.data"], in: .import)
        picker.delegate = self
        picker.modalPresentationStyle = .fullScreen
        present(picker, animated: true)
    }
}

extension ClientCertificateManagementViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        guard let vc = UIStoryboard.init(name: "Certificates", bundle: nil).instantiateViewController(withIdentifier: ClientCertificateImportViewController.storyboadIdentifier) as? ClientCertificateImportViewController else {
            return
        }
        vc.viewModel = ClientCertificateImportViewModel(certificateUrl: url, delegate: vc)
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
}

// MARK: - Private

extension ClientCertificateManagementViewController {
    private func configureAppearance() {
        selectCertificateTitleLabel.font = UIFont.pepFont(style: .title2, weight: .regular)
        selectCertificateTitleLabel.adjustsFontForContentSizeCategory = true
        selectCertificateSubtitleLabel.font = UIFont.pepFont(style: .title3, weight: .regular)
        selectCertificateSubtitleLabel.adjustsFontForContentSizeCategory = true

        addCertButton.titleLabel?.font = UIFont.pepFont(style: .body, weight: .regular)
        addCertButton.titleLabel?.adjustsFontForContentSizeCategory = true

        if #available(iOS 13, *) {
            Appearance.customiseForLogin(viewController: self)
        } else {
            navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationController?.navigationBar.shadowImage = UIImage()
            navigationController?.navigationBar.isTranslucent = true
            navigationController?.navigationBar.backgroundColor = UIColor.clear
        }
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.isHidden = false
        let image = UIImage(named: "button-add")
        addCertButton.setImage(image?.withRenderingMode(.alwaysTemplate), for: .normal)
        addCertButton.tintColor = UIColor.white

        let backButtonTitle = NSLocalizedString("Cancel",
                                                comment: "Back button for client cert managment")
        let newBackButton = UIBarButtonItem(title: backButtonTitle,
                                            style: .plain,
                                            target: self,
                                            action: #selector(backButton))
        navigationItem.leftBarButtonItem = newBackButton
    }
    
    @objc private func backButton() {
        navigationController?.popViewController(animated: true)
    }

    private func setupTableView() {
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
        let select = vm.handleDidSelect(rowAt: indexPath)
        switch select {
        case .newAccount:
            performSegue(withIdentifier: SegueIdentifier.showLogin, sender: self)
        case .updateCertificate:
            navigationController?.popViewController(animated: true)
        }
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ClientCertificateManagementTableViewCell.reusableId) as? ClientCertificateManagementTableViewCell else {
            Log.shared.errorAndCrash("No reusable cell")
            // We prefer empty cell than app crash
            return UITableViewCell()
        }
        cell.delegate = self
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            // We prefer empty cell than app crash
            return UITableViewCell()
        }
        let row = vm.rows[indexPath.row]
        let date = Localized.importDate + ": " + row.date
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
            let dvm = vm.loginViewModel()
            dvc.viewModel = dvm
        }
    }
}

// MARK: - Swipe actions

extension ClientCertificateManagementViewController: SwipeTableViewCellDelegate {
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        
        // Create swipe actions, taking the currently displayed folder into account
        var swipeActions = [SwipeAction]()
        let swipeActionDescriptor = SwipeActionDescriptor.trash
        let deleteAction =
            SwipeAction(style: .destructive,
                        title: swipeActionDescriptor.title(forDisplayMode: .titleAndImage)) {
                            [weak self] action, indexPath in
                            guard let me = self else {
                                Log.shared.lostMySelf() 
                                return
                            }
                            me.swipeDelete = action
                            me.deleteAction(forCellAt: indexPath)
        }
        configure(action: deleteAction, with: swipeActionDescriptor)
        swipeActions.append(deleteAction)
        return swipeActions
    }
    
    func deleteAction(forCellAt: IndexPath) {
        guard let vm = viewModel else { return }
        let deleteSuccess = vm.deleteCertificate(indexPath: forCellAt)
        if deleteSuccess {
            if let swipeDelete = self.swipeDelete {
                swipeDelete.fulfill(with: .delete)
                self.swipeDelete = nil
            }
        } else {
            if let swipeDelete = self.swipeDelete {
                swipeDelete.fulfill(with: .reset)
                self.swipeDelete = nil
            }
        }
    }
    
    func configure(action: SwipeAction, with descriptor: SwipeActionDescriptor) {
        action.title = descriptor.title(forDisplayMode: buttonDisplayMode)
        action.image = descriptor.image(forStyle: buttonStyle, displayMode: buttonDisplayMode)
        
        switch buttonStyle {
        case .backgroundColor:
            action.backgroundColor = descriptor.color
        case .circular:
            action.backgroundColor = .clear
            action.textColor = descriptor.color
            action.font = .systemFont(ofSize: 13)
            action.transitionDelegate = ScaleTransition.default
        }
    }
    
    func tableView(_ tableView: UITableView,
                   editActionsOptionsForRowAt indexPath: IndexPath,
                   for orientation: SwipeActionsOrientation) -> SwipeTableOptions {
        var options = SwipeTableOptions()
        options.transitionStyle = .border
        options.buttonSpacing = 11
        options.expansionStyle = .destructive(automaticallyDelete: false)
        return options
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? EmailListViewCell else {
            return
        }
        cell.clear()
    }
}

extension ClientCertificateManagementViewController: ClientCertificateManagementViewModelDelegate {
    func showInUseError(by: String) {
        let errorString = NSLocalizedString("You can only delete certificates that are not connected to an account. The certificate is currently used for the following account: \(by)", comment: "alert error message certificate delete")
        UIUtils.showAlertWithOnlyPositiveButton(title: NSLocalizedString("Not possible to delete", comment: "alert error title certificate delete") ,
                                                message: errorString)
    }
}

// MARK: - ClientCertificateImport Delegate
extension ClientCertificateManagementViewController: ClientCertificateImportViewControllerDelegate {
    func certificateCouldImported() {
        viewModel?.handleNewCertificateImported()
        tableView.reloadData()
    }
}

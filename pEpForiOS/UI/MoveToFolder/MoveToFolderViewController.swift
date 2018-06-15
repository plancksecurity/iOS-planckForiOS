//
//  MoveToFolderViewController.swift
//  pEp
//
//  Created by Andreas Buff on 08.05.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

/// Enables the user to move an IMAP message to a folder of her choice
class MoveToFolderViewController: BaseViewController {
    let storyboardId = "MoveToFolderViewController"
    //weak var delegate : MoveToFolderDelegate?
    @IBOutlet var tableview: UITableView!
    var viewModel: MoveToAccountViewModel?
    private let cellId = "AccountCell"

    //private var viewModel: FolderViewModel?


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setup()
        tableview.reloadData()
    }

    // MARK: - SETUP

    private func setup() {
        setupNavigationBar()
        setupTableView()
        //setupViewModel()
    }

    private func setupTableView() {
        tableview.dataSource = self
        tableview.delegate = self
        hideSeperatorForEmptyCells()
    }

    private func hideSeperatorForEmptyCells() {
        // Add empty footer to not show empty cells (visible as dangling seperators)
        tableview.tableFooterView = UIView(frame: .zero)
    }

    private func setupNavigationBar() {
        title = NSLocalizedString("Move To", comment: "MoveToFolderViewController title")
        navigationItem.leftBarButtonItem = UIBarButtonItem(title:
            NSLocalizedString("Cancel",
                              comment: "MoveToFolderViewController NavigationBar canel button title"),
                                                           style:.plain,
                                                           target:self,
                                                           action:#selector(self.backButton))
    }

    // MARK: - ACTION

    @objc func backButton() {
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource

extension MoveToFolderViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let vm = viewModel {
            return vm.count
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        if let vm = viewModel?[indexPath.row] {
            cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
            cell.textLabel?.text = vm.title
        }
        return cell
    }

}

// MARK: - UITableViewDelegate
extension MoveToFolderViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //perform segue con el viewmodel inicializado de la siguiente vista.
    }
}

/*
// MARK: - SELECTABILITY

private extension MoveToFolderViewController {
    private func isSelectable(rowAt indexPath: IndexPath) -> Bool {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash(component: #function, errorString: "No model")
            return false
        }
        let fcvm = vm[indexPath.section][indexPath.row]
        return !MoveToFolderViewController.folderTypesNotAllowedToMoveTo.contains(fcvm.folder.folderType)
    }
}

private extension Message {
    func isAllowedToMoveTo(targetFolder: Folder) -> Bool {
        return
            !MoveToFolderViewController.folderTypesNotAllowedToMoveTo.contains(targetFolder.folderType)
                && parent != targetFolder
    }
}*/

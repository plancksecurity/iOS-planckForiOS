//
//  MoveToFolderViewController.swift
//  pEp
//
//  Created by Andreas Buff on 08.05.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

/// Enables the user to move an IMAP message to a folder of her choice
class MoveToAccountViewController: BaseViewController {
    let storyboardId = "MoveToAccountViewController"
    @IBOutlet var tableview: UITableView!
    var viewModel: MoveToAccountViewModel?
    private let cellId = "AccountCell"
    private var selectedViewModel : moveToFolderViewModel?
    weak var delegate : MoveToFolderDelegate?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setup()
        tableview.reloadData()
    }

    // MARK: - SETUP

    private func setup() {
        setupNavigationBar()
        setupTableView()
    }

    private func setupTableView() {
        BaseTableViewController.setupCommonSettings(tableView: tableview)
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

extension MoveToAccountViewController: UITableViewDataSource {

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

extension MoveToAccountViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedViewModel = viewModel?[indexPath.row].viewModel()
        performSegue(withIdentifier: "showAccount", sender: self)
    }
}

// Mark: - Segue

extension MoveToAccountViewController {

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showAccount" {
            if let vc = segue.destination as? MoveToFolderTableViewController, let appCfg = self.appConfig, let vm = selectedViewModel {
                vc.appConfig = appCfg
                vm.delegate = self.delegate
                vc.viewModel = vm
            }
        }
    }
}

//
//  MoveToFolderViewController.swift
//  pEp
//
//  Created by Andreas Buff on 08.05.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

import PlanckToolbox

/// Enables the user to move an IMAP message to a folder of her choice
class MoveToAccountViewController: UIViewController {
    static let storyboardId = "MoveToAccountViewController"
    private let cellId = "AccountCell"
    private let showAccountSegueIdentifier = "showAccount"
    private var selectedViewModel : MoveToFolderViewModel?
    @IBOutlet private var tableview: UITableView!

    var viewModel: MoveToAccountViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    // MARK: - SETUP

    private func setup() {
        setupNavigationBar()
        setupTableView()
        view.backgroundColor = tableview.backgroundColor
    }

    private func setupTableView() {
        tableview.hideSeperatorForEmptyCells()
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
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return 0
        }
        return vm.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return UITableViewCell()
        }
        let row = vm[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.text = row.title
        cell.textLabel?.font = UIFont.pepFont(style: .callout, weight: .regular)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension MoveToAccountViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        selectedViewModel = vm[indexPath.row].viewModel()
        performSegue(withIdentifier: showAccountSegueIdentifier, sender: self)
    }
}

// Mark: - Segue

extension MoveToAccountViewController {

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showAccountSegueIdentifier {
            if let vc = segue.destination as? MoveToFolderTableViewController, let vm = selectedViewModel {
                vc.viewModel = vm
            }
        }
    }
}

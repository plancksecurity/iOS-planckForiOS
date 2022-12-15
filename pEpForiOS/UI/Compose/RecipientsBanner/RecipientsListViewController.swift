//
//  RecipientsListViewController.swift
//  pEpForiOS
//
//  Created by Martín Brude on 28/11/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import UIKit

#if EXT_SHARE
import MessageModelForAppExtensions
import pEpIOSToolboxForExtensions
#else
import MessageModel
import pEpIOSToolbox
#endif

class RecipientsListViewController: UIViewController {

    var viewModel: RecipientsListViewModel?

    @IBOutlet weak var removeAllButton: UIButton!

    @IBOutlet private weak var tableView: UITableView!

    @IBAction func removeAllButtonPressed() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        vm.removeAll()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.setEditing(true, animated: true)
        tableView.allowsMultipleSelectionDuringEditing = true
        removeAllButton.setTitleColor(.pEpRed, for: .normal)
        showNavigationBarSecurityBadge(pEpRating: .mistrust)
    }
}

// MARK: - UITableViewDataSource

extension RecipientsListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return 0
        }
        return vm.numberOfRows
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return UITableViewCell()
        }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: RecipientListTableViewCell.cellIdentifier, for: indexPath) as? RecipientListTableViewCell else {
            return UITableViewCell()
        }
        cell.addressLabel.text = vm[indexPath.row].address
        cell.usernameLabel.text = vm[indexPath.row].username
        return cell
    }
}

// MARK: - RecipientsListViewDelegate

extension RecipientsListViewController: RecipientsListViewDelegate {

    func reload() {
        tableView.reloadData()
    }

    func reloadAndDismiss() {
        tableView.reloadData()
        dismiss(animated: true)
    }
}

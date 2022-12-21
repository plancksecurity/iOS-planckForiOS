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

    public var viewModel: RecipientsListViewModel?

    @IBOutlet private weak var removeAllButton: UIButton!
    @IBOutlet private weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = 60.0
        removeAllButton.setTitleColor(.pEpRed, for: .normal)
        showNavigationBarSecurityBadge(pEpRating: .mistrust)
    }

    @IBAction func removeAllButtonPressed() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        vm.removeAll()
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
            return RecipientListTableViewCell()
        }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: RecipientListTableViewCell.cellIdentifier, for: indexPath) as? RecipientListTableViewCell else {
            Log.shared.errorAndCrash("Can't dequeue cell. Unexpected")
            return RecipientListTableViewCell()
        }
        let address = vm[indexPath.row].address
        let username = vm[indexPath.row].username
        cell.configure(address: address, username: username)
        return cell
    }
}

// MARK: - RecipientsListViewDelegate

extension RecipientsListViewController: RecipientsListViewDelegate {

    func reloadAndDismiss() {
        tableView.reloadData()
        dismiss(animated: true)
    }
}

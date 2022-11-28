//
//  RecipientsListViewController.swift
//  pEpForiOS
//
//  Created by Martín Brude on 28/11/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import UIKit

#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

class RecipientsListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    var viewModel: RecipientsListViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.setEditing(true, animated: true)
        tableView.allowsMultipleSelectionDuringEditing = true
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .insert
    }
}

extension RecipientsListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return UITableViewCell()
        }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: RecipientListTableViewCell.cellIdentifier, for: indexPath) as? RecipientListTableViewCell else {
            return UITableViewCell()
        }
        cell.addressLabel.text = vm[indexPath.row].address
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return 0
        }
        return vm.numberOfRows
    }
}

extension RecipientsListViewController: UITableViewDelegate {

}

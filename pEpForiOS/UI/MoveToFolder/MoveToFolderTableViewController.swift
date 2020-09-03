//
//  MoveToFolderTableViewController.swift
//  pEp
//
//  Created by Xavier Algarra on 15/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

class MoveToFolderTableViewController: UITableViewController {

    var viewModel : MoveToFolderViewModel?
    let storyboardId = "MoveToFolderViewController"
    private let cellId = "FolderCell"
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.title = title
        tableView.hideSeperatorForEmptyCells()
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let vm = viewModel {
            return vm.count
        }
        return 0
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        if let vm = viewModel?[indexPath.row] {
            cell.textLabel?.text = vm.title
            cell.imageView?.image = vm.icon
            cell.textLabel?.font = UIFont.pepFont(style: .callout, weight: .regular)
            if !vm.isSelectable {
                cell.isUserInteractionEnabled = false
                cell.selectionStyle = .none
                cell.textLabel?.isEnabled = false
            } else {
                cell.accessoryType = .disclosureIndicator
            }
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int {
        if let vm = viewModel?[indexPath.row] {
            return vm.indentationLevel
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        vm.moveMessagesTo(index: indexPath.row)
        dismiss(animated: true)
    }
}

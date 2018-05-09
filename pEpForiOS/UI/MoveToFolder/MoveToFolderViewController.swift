//
//  MoveToFolderViewController.swift
//  pEp
//
//  Created by Andreas Buff on 08.05.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

/// Enables the user to move an IMAP message to a folder of her choice
class MoveToFolderViewController: BaseViewController {
    let storyboardId = "MoveToFolderViewController"

    @IBOutlet var tableview: UITableView!

    private let cellId = "MoveToFolderCell"
    private let indentationWidth: CGFloat = 20.0
    private var viewModel: FolderViewModel?
    var message: Message?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableview.dataSource = self
        tableview.delegate = self
        setupView()
        tableview.reloadData()
    }

    private func setupView() {
        guard let acc = message?.parent.account else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "What are we supposed to display?")
            return
        }
        viewModel = FolderViewModel(withFordersIn: [acc])
    }
}

// MARK: - UITableViewDataSource

extension MoveToFolderViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel?.count ?? 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?[section].count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        guard let vm = viewModel else {
            Log.shared.errorAndCrash(component: #function, errorString: "No model")
            return cell
        }
        let fcvm = vm[indexPath.section][indexPath.row]
        cell.textLabel?.text = fcvm.title
        cell.imageView?.image = fcvm.icon
        cell.indentationWidth = indentationWidth
        return cell
    }

    func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash(component: #function, errorString: "No model")
            return 0
        }
        return vm[indexPath.section][indexPath.row].level - 1
    }
}

// MARK: - UITableViewDelegate

extension MoveToFolderViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let vm = viewModel, let msg = message else {
            Log.shared.errorAndCrash(component: #function, errorString: "missing data")
            return
        }
        let folderCellVM = vm[indexPath.section][indexPath.row]
        folderCellVM.moveIn(message: msg)
        dismiss(animated: true)
    }
}

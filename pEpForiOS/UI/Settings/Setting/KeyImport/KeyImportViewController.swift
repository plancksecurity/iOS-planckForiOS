//
//  KeyImportViewController.swift
//  pEp
//
//  Created by Dirk Zimmermann on 14.05.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

class KeyImportViewController: BaseViewController {
    static private let cellID = "KeyImportTableViewCell"

    public var viewModel = KeyImportViewModel() {
        didSet {
            viewModel.delegate = self
        }
    }

    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super .viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
}

// MARK: - UITableViewDelegate

extension KeyImportViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.handleDidSelect(rowAt: indexPath)
    }
}

// MARK: - UITableViewDataSource

extension KeyImportViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: KeyImportViewController.cellID)
            else {
                return UITableViewCell()
        }

        cell.textLabel?.text = viewModel.rows[indexPath.row].fileName

        return cell
    }
}

// MARK: - KeyImportViewModelDelegate

extension KeyImportViewController: KeyImportViewModelDelegate {
    func showConfirmSetOwnKey(key: KeyImportViewModel.KeyDetails) {
        // TODO
    }

    func showError(with title: String, message: String) {
        // TODO
    }

    func showSetOwnKeySuccess() {
        // TODO
    }
}

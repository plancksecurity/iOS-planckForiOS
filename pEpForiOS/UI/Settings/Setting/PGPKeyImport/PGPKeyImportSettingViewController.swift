//
//  PGPKeyImportViewController.swift
//  pEp
//
//  Created by Andreas Buff on 14.05.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

class PGPKeyImportSettingViewController: BaseViewController {
    static private let cellID = "PGPKeyImportSettingTableViewCell"
    public var viewModel: PGPKeyImportSettingViewModel?
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

extension PGPKeyImportSettingViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }
        vm.handleDidSelect(rowAt: indexPath)
    }

}

// MARK: - UITableViewDataSource

extension PGPKeyImportSettingViewController: UITableViewDataSource {

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return []
        }
        return vm.sections.map { $0.title }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return 0
        }
        return vm.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return 0
        }
        return vm.sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return UITableViewCell()
        }
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: PGPKeyImportSettingViewController.cellID)
            else {
                return UITableViewCell()
        }
        cell.textLabel?.text = vm.sections[indexPath.section].rows[indexPath.row].title

        return cell
    }
}

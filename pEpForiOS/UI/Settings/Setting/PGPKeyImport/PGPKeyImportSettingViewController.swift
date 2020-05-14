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
    public var viewModel: PGPKeyImportSettingViewModel? {
        didSet {
            viewModel?.delegate = self
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
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return nil
        }
        return vm.sections[section].title
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

//segueSetOwnKey

// MARK: - Segue

extension PGPKeyImportSettingViewController {

    enum SegueIdentifier: String {
        case segueSetOwnKey
        case segueImportKeyFromDocuments
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueIdentifier = segue.identifier else {
            Log.shared.errorAndCrash("No Segue ID")
            return
        }

        switch SegueIdentifier(rawValue: segueIdentifier) {
        case .segueSetOwnKey:
//            guard
//                let destination = segue.destination as? AccountSettingsTableViewController,
//                let indexPath = sender as? IndexPath
//                else {
//                    Log.shared.errorAndCrash("Requirements not met.")
//                    return
//            }
//            destination.appConfig = appConfig
//            destination.viewModel = viewModel.accountSettingsViewModel(forAccountAt: indexPath)
            break
        case .segueImportKeyFromDocuments:
//            guard let destination = segue.destination as? BaseTableViewController else { return }
//            destination.appConfig = self.appConfig
            break
        case .none:
            Log.shared.errorAndCrash("No segue")
        }
    }

}

// MARK: - PGPKeyImportSettingViewModelDelegate

extension PGPKeyImportSettingViewController: PGPKeyImportSettingViewModelDelegate {
    func showSetPgpKeyImportScene() {
        performSegue(withIdentifier: SegueIdentifier.segueImportKeyFromDocuments.rawValue,
                     sender: nil)
    }

    func showSetOwnKeyScene() {
        performSegue(withIdentifier: SegueIdentifier.segueSetOwnKey.rawValue,
                     sender: nil)
    }
}

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
        title = NSLocalizedString("PGP Key Import",
                                  comment: "PGPKeyImportSettingViewController Navigationbar title")
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

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
//    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        guard let vm = viewModel else {
//            Log.shared.errorAndCrash("No VM")
//            return nil
//        }
//        return vm.sections[section].title
//    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return nil
        }
        let view = UIView()
        let label = UILabel()
        label.numberOfLines = 0
        view.addSubview(label)
        label.fullSizeInSuperView()
        label.text = vm.sections[section].title

        return view
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
        let row = vm.sections[indexPath.section].rows[indexPath.row]
        cell.textLabel?.text = row.title
        if row.type == .setOwnKey {
            cell.accessoryType = .disclosureIndicator
        }

        return cell
    }
}

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
            // SetOwnKeyViewController does not need any preparation
            break
        case .segueImportKeyFromDocuments:
            fatalError("VC does not exist yet")
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

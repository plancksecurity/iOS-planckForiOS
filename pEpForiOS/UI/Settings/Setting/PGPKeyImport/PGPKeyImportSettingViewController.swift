//
//  PGPKeyImportViewController.swift
//  pEp
//
//  Created by Andreas Buff on 14.05.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel
import pEpIOSToolbox

class PGPKeyImportSettingViewController: BaseViewController {
    static private let switchCellID = "PGPKeyImportSettingsSwitchTableViewCell"
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
        tableView.backgroundColor = .groupTableViewBackground
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 100
        tableView.register(PEPHeaderView.self,
                           forHeaderFooterViewReuseIdentifier: PEPHeaderView.reuseIdentifier)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showNavigationBar()
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
        tableView.deselectRow(at: indexPath, animated: false)
    }
}

// MARK: - UITableViewDataSource

extension PGPKeyImportSettingViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return nil
        }

        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: PEPHeaderView.reuseIdentifier) as? PEPHeaderView else {
            Log.shared.errorAndCrash("pEpHeaderView doesn't exist!")
            return nil
        }
        // User has to be able to click on the link
        headerView.isUserInteractionEnabled = true
        headerView.attributedTitle = vm.sections[section].title
        return headerView
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

        let row = vm.sections[indexPath.section].rows[indexPath.row]
        switch row.type {
        case .passphrase:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: PGPKeyImportSettingViewController.switchCellID) as? PGPKeyImportSettingSwitchTableViewCell else {
                Log.shared.errorAndCrash("PGPKeyImportSettingSwitchTableViewCell not found")
                return UITableViewCell()
            }
            cell.titleLabel?.text = row.title
            cell.titleLabel?.font = UIFont.pepFont(style: .body, weight: .regular)
            if let fontColor = row.titleFontColor {
                cell.titleLabel?.textColor = fontColor
            }
            cell.delegate = self
            cell.passphraseSwitch.isOn = vm.isPassphraseForNewKeysEnabled()
            return cell
        case .pgpKeyImport, .setOwnKey:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: PGPKeyImportSettingViewController.cellID) else {
                Log.shared.errorAndCrash("PGPKeyImportSettingTableViewCell not found")
                return UITableViewCell()
            }
            cell.textLabel?.font = UIFont.pepFont(style: .body, weight: .regular)
            cell.textLabel?.text = row.title

            if row.isEnabled {
                if let fontColor = row.titleFontColor {
                    cell.textLabel?.textColor = fontColor

                }
            } else {
                cell.textLabel?.textColor = .gray
            }

            if row.type == .setOwnKey && row.isEnabled {
                cell.accessoryType = .disclosureIndicator
            }
            return cell
        }
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
            guard let vc = segue.destination as? KeyImportViewController else {
                Log.shared.errorAndCrash("No KeyImportViewController as segue destination")
                return
            }
            vc.appConfig = appConfig
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

// MARK : PGPKeyImportSettingSwitchTableViewCellDelegate

extension PGPKeyImportSettingViewController : PGPKeyImportSettingSwitchTableViewCellDelegate  {
    func passphraseSwitchChanged(sender: PGPKeyImportSettingSwitchTableViewCell, didChangeSwitchValue newValue: Bool, cancelCallback: (() -> Void)?) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }

        if newValue {
            UIUtils.showUserPassphraseForNewKeysAlert(cancelCallback: cancelCallback)
        } else {
            vm.stopUsingPassphraseForNewKeys()
        }
    }
}

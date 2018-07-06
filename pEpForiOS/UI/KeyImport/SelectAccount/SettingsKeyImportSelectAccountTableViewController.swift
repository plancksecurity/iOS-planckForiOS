//
//  SettingsKeyImportSelectAccountTableViewController.swift
//  pEp
//
//  Created by Hussein on 18/05/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

/// Lets the user choose the mail account used to start keyImport

class SettingsKeyImportSelectAccountTableViewController: BaseTableViewController {
    let storyboardID = "SettingsKeyImportSelectAccountTableViewController"
    let cellID = "SettingsKeyImportSelectAccountCell"

    private var viewModel: SettingsKeyImportSelectAccountViewModel?
    private var selectedViewModel: AutoWizardStepsViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
    
    // MARK - Setup
    private func setup() {
        let keyImportService: KeyImportServiceProtocol = appConfig.keyImportService
        viewModel = SettingsKeyImportSelectAccountViewModel(keyImportService: keyImportService)
    }

    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let vm = viewModel else {
            return 0
        }
        return vm.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell { //TODO ask
            let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
            cell.tintColor = UIColor.pEpGreen

            if let vm = viewModel {
                let address = vm[indexPath.row].address
                cell.textLabel?.text = address
            }

            return cell
    }
    
    override func tableView(_ tableView: UITableView,
                            titleForHeaderInSection section: Int) -> String? {
        return NSLocalizedString("Account to key import",
                                 comment: "Key import Setting Section Title")
    }
    
    // MARK: - UITableviewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let vm = viewModel {
            selectedViewModel = vm[indexPath.row].getWizardViewModel()
            self.performSegue(withIdentifier: "segueToStartKeyImport", sender: self)
        }

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? AutoWizardStepsViewController,
            let wizardVM = selectedViewModel {
            destination.appConfig = self.appConfig
            destination.viewModel = wizardVM
        }
    }
}

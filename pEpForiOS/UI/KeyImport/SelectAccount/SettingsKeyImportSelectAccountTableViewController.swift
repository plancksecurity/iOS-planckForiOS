//
//  SettingsKeyImportSelectAccountTableViewController.swift
//  pEp
//
//  Created by Hussein on 18/05/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit
//Todo: Move to MVVM
import MessageModel


/// Lets the user choose the mail account used to start keyImport

class SettingsKeyImportSelectAccountTableViewController: BaseTableViewController {
    let storyboardID = "SettingsKeyImportSelectAccountTableViewController"
    let cellID = "SettingsKeyImportSelectAccountCell"
    var allAccounts : [Account] {
        return Account.all()
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allAccounts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        let address = allAccounts[indexPath.row].user.address
        cell.textLabel?.text = address
        cell.tintColor = UIColor.pEpGreen
       // if let defaultAccountAddress = AppSettings().defaultAccount,
       //     defaultAccountAddress == address {
       //     cell.accessoryType = .checkmark
       // } else {
       //     cell.accessoryType = .none
       //}
        return cell
    }
    
    override func tableView(_ tableView: UITableView,
                            titleForHeaderInSection section: Int) -> String? {
        return NSLocalizedString("Account to key import",
                                 comment: "Key import Setting Section Title")
    }
    
    // MARK: - UITableviewDelegate
    //Todo remove: onitemclick
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
        let selectedAccount = allAccounts[indexPath.row]
        showToast(message: selectedAccount.user.address)
        //AppSettings().defaultAccount = selectedAccount.user.address
        //tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? AutoWizardStepsViewController {
            destination.appConfig = self.appConfig 
        }
    }
}

extension UIViewController {
    
    func showToast(message : String) {
        
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height-500, width: 150, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center;
        toastLabel.font = UIFont(name: "Montserrat-Light", size: 12.0)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    } }

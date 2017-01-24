//
//  PrivacyStatusTableViewController.swift
//  Trustwords
//
//  Created by Igor Vojinovic on 12/28/16.
//  Copyright © 2016 Igor Vojinovic. All rights reserved.
//

import UIKit
import MessageModel

class PrivacyStatusTableViewController: UITableViewController {
    
    var message: Message!
    var appConfig: AppConfig!
    var allRecipients: [Identity] = []
    var selectedIdentity: Identity!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()
        allRecipients = Array(message.allIdentities)
    }
    
    func configureTableView() {
        tableView.estimatedRowHeight = 44.0
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        }
        return allRecipients.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let infoCell = tableView.dequeueReusableCell(withIdentifier: PrivacyInfoTableViewCell.reuseIdentifier,
                                                         for: indexPath) as! PrivacyInfoTableViewCell
            if indexPath.row == 0 {
                infoCell.showExplanation()
            }
            else {
                infoCell.showSuggestion()
            }
            return infoCell
        }
        let handshakeCell = tableView.dequeueReusableCell(withIdentifier: HandshakeTableViewCell.reuseIdentifier,
                                                          for: indexPath) as! HandshakeTableViewCell
        handshakeCell.updateCell(allRecipients, indexPath: indexPath)
        return handshakeCell
    }
    
    // MARK: - Actions
    
    @IBAction func handshakeButtonTapped(_ sender: RoundedButton) {
        selectedIdentity = allRecipients[sender.tag]
        performSegue(withIdentifier: .segueHandshake, sender: self)
    }
    
}

extension PrivacyStatusTableViewController: SegueHandlerType {
    
    // MARK: - SegueHandlerType
    
    enum SegueIdentifier: String {
        case segueHandshake
        case noSegue
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination = segue.destination as? TrustwordsTableViewController
        destination?.message = message
        destination?.appConfig = appConfig
        destination?.partnerIdentity = selectedIdentity
        destination?.myselfContact = PEPUtil.mySelfIdentity(message)
    }
}

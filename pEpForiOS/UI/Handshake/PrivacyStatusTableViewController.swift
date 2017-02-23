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
    enum Rows: Int {
        case explanations = 0
        case identities
    }

    var message: Message!
    var appConfig: AppConfig!
    var allRecipients: [Identity] = []
    var selectedIdentity: Identity?
    var ratingReEvaluator: RatingReEvaluator?

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()
        allRecipients = Array(message.identitiesEligibleForHandshake(session: appConfig.session))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showPepRating(pEpRating: message.pEpRating())
    }
    
    func configureTableView() {
        tableView.estimatedRowHeight = 44.0
    }

    // MARK: - UITableViewDataSource

    override func tableView(
        _ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == Rows.explanations.rawValue {
            return 2
        }
        return allRecipients.count
    }
    
    override func tableView(
        _ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == Rows.explanations.rawValue {
            let infoCell = tableView.dequeueReusableCell(
                withIdentifier: PrivacyInfoTableViewCell.reuseIdentifier,
                for: indexPath) as! PrivacyInfoTableViewCell
            if indexPath.row == Rows.explanations.rawValue {
                infoCell.showExplanation(message: message)
            } else {
                infoCell.showSuggestion(message: message)
            }
            return infoCell
        }
        let handshakeCell = tableView.dequeueReusableCell(
            withIdentifier: HandshakeTableViewCell.reuseIdentifier,
            for: indexPath) as! HandshakeTableViewCell
        handshakeCell.session = appConfig.session
        handshakeCell.updateCell(allRecipients, indexPath: indexPath)
        return handshakeCell
    }
    
    // MARK: - Actions
    
    @IBAction func handshakeButtonTapped(_ sender: RoundedButton) {
        selectedIdentity = allRecipients[sender.tag]
        if let id = selectedIdentity, id.canResetTrust(session: appConfig.session) {
            PEPUtil.resetTrust(identity: id)
            ratingReEvaluator?.decryptAgain()
            tableView.reloadRows(
                at: [IndexPath(row: sender.tag, section: Rows.identities.rawValue)],
                with: .automatic)
        } else {
            performSegue(withIdentifier: .segueHandshake, sender: self)
        }
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
        switch segueIdentifier(for: segue) {
        case .segueHandshake:
            let destination = segue.destination as? TrustwordsTableViewController
            destination?.message = message
            destination?.appConfig = appConfig
            destination?.partnerIdentity = selectedIdentity
            destination?.myselfIdentity = PEPUtil.ownIdentity(message: message)
        case .noSegue:
            break
        }
    }
}

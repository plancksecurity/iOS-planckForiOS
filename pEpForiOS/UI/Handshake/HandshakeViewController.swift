//
//  HandshakeViewController.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 19.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

class HandshakeViewController: UITableViewController {
    var appConfig: AppConfig?

    var message: Message? {
        didSet {
            partners = message?.identitiesEligibleForHandshake() ?? []
        }
    }

    var ratingReEvaluator: RatingReEvaluator?
    var partners = [Identity]()
    let imageProvider = IdentityImageProvider()

    override func awakeFromNib() {
        tableView.estimatedRowHeight = 72.0
        tableView.rowHeight = UITableViewAutomaticDimension
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return partners.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(
            withIdentifier: "handshakePartnerCell",
            for: indexPath) as? HandshakePartnerTableViewCell {
            if let m = message {
                let theId = partners[indexPath.row]
                cell.updateCell(indexPath: indexPath, message: m, partner: theId,
                                session: appConfig?.session, imageProvider: imageProvider)
            }
            return cell
        }

        return UITableViewCell()
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? HandshakePartnerTableViewCell {
            cell.didChangeSelection()
            tableView.updateSize()
        }
    }
}
